import { mkdirSync, copyFileSync, readFileSync } from 'fs';
import { join } from 'path';
import { NestFactory } from '@nestjs/core';
import { getRepositoryToken } from '@nestjs/typeorm';
import * as bcrypt from 'bcryptjs';
import { Repository } from 'typeorm';
import { AppModule } from './app.module';
import { Role } from './features/authentication/domain/entities/role.entity';
import { User } from './features/authentication/domain/entities/user.entity';
import { UserStatus } from './features/authentication/domain/enums/user-status.enum';
import { Department } from './features/departments/domain/entities/department.entity';
import { Employee } from './features/employee/domain/entities/employee.entity';
import { EmploymentStatus } from './features/employee/domain/enums/employment-status.enum';
import { EmploymentType } from './features/employee/domain/enums/employment-type.enum';
import { WorkMode } from './features/employee/domain/enums/work-mode.enum';
import { generateTemporaryPassword } from './features/employee/application/generate-temporary-password.util';

// Source data extracted from the Odoo "hr.employee" export the user provided
// (Employee (hr.employee).xlsx, 27 rows, no Department/Manager columns).
// See scratchpad xlsx-inspect/extract.js for how employees.json and
// avatars/ were produced.
const SOURCE_DIR =
  'C:\\Users\\noush\\AppData\\Local\\Temp\\claude\\C--Users-noush-OneDrive-Desktop-Zera-ERP\\386f88b2-6c7d-4e27-bc21-fd54e5c71039\\scratchpad\\xlsx-inspect';

interface SourceRow {
  name: string;
  jobTitle: string;
  workEmail: string | null;
  workPhone: string | null;
  birthday: string | null;
  contractStart: string | null;
  tags: string;
  workLocationName: string | null;
  imageFile: string | null;
}

// The file has no joining date for the CEO; this is his known, real start
// date (already on record before this import replaced the old data).
const KNOWN_JOINING_DATES: Record<string, string> = {
  'Noushad Ranani': '2016-06-02',
};

function inferDepartment(jobTitle: string): string {
  const title = jobTitle.toLowerCase();
  if (title.includes('chief executive')) return 'Management';
  if (title.includes('hr manager') || title.includes('hrbp')) return 'HR';
  if (title.includes('seo')) return 'SEO';
  if (title.includes('sales')) return 'Sales';
  if (title.includes('web developer')) return 'Web Development';
  if (title.includes('graphic designer')) return 'Design';
  if (title.includes('content writer')) return 'Content';
  if (
    title.includes('digital marketing') ||
    title.includes('social media marketing')
  ) {
    return 'Digital Marketing';
  }
  return 'General';
}

function inferRole(row: SourceRow): string {
  if (row.tags === 'CEO') return 'Super Admin';
  if (row.tags === 'HR') return 'HR/Manager';
  if (/manager/i.test(row.jobTitle)) return 'Team Lead';
  return 'Employee';
}

function buildEmailAssignments(names: string[]): Map<string, string> {
  const used = new Set<string>();
  const emails = new Map<string, string>();
  for (const name of names) {
    const tokens = name.trim().split(/\s+/);
    const first = tokens[0].toLowerCase();
    let candidate = `${first}.${tokens[tokens.length - 1].toLowerCase()}`;
    if (used.has(candidate) && tokens.length > 2) {
      candidate = `${first}.${tokens.slice(1).join('').toLowerCase()}`;
    }
    used.add(candidate);
    emails.set(name, `${candidate}@zeracreative.com`);
  }
  return emails;
}

async function run() {
  const rows = JSON.parse(
    readFileSync(join(SOURCE_DIR, 'employees.json'), 'utf-8'),
  ) as SourceRow[];

  const app = await NestFactory.createApplicationContext(AppModule);

  const userRepo = app.get<Repository<User>>(getRepositoryToken(User));
  const roleRepo = app.get<Repository<Role>>(getRepositoryToken(Role));
  const departmentRepo = app.get<Repository<Department>>(
    getRepositoryToken(Department),
  );
  const employeeRepo = app.get<Repository<Employee>>(
    getRepositoryToken(Employee),
  );

  // --- Wipe the existing (stale/placeholder) employee roster ---
  const existingEmployees = await employeeRepo.find();
  if (existingEmployees.length > 0) {
    const userIds = existingEmployees.map((e) => e.userId);
    const existingIds = existingEmployees.map((e) => e.id);
    // Clear self-referencing manager links first so the FK doesn't block
    // deletion, then remove employees and their linked user accounts.
    await employeeRepo
      .createQueryBuilder()
      .update(Employee)
      .set({ reportingManagerId: null as unknown as string })
      .where('id IN (:...ids)', { ids: existingIds })
      .execute();
    await employeeRepo.remove(existingEmployees);
    await userRepo.delete(userIds);
    console.log(`Removed ${existingEmployees.length} existing employees.`);
  }

  // --- Departments, inferred from job title since the export has none ---
  const departmentNames = [...new Set(rows.map((r) => inferDepartment(r.jobTitle)))];
  const departmentsByName = new Map<string, Department>();
  for (const name of departmentNames) {
    let dept = await departmentRepo.findOne({ where: { name } });
    dept ??= await departmentRepo.save(departmentRepo.create({ name }));
    departmentsByName.set(name, dept);
  }
  console.log(`Departments ready: ${departmentNames.join(', ')}`);

  const roleAssignments = new Map(rows.map((r) => [r.name, inferRole(r)]));
  const emailAssignments = buildEmailAssignments(rows.map((r) => r.name));

  const rolesByName = new Map<string, Role>();
  for (const roleName of new Set(roleAssignments.values())) {
    const role = await roleRepo.findOneOrFail({ where: { name: roleName } });
    rolesByName.set(roleName, role);
  }

  const avatarsDir = join(__dirname, '..', 'uploads', 'avatars');
  mkdirSync(avatarsDir, { recursive: true });

  const created: {
    employeeCode: string;
    name: string;
    role: string;
    email: string;
    temporaryPassword: string;
  }[] = [];

  let sequence = 0;

  for (const row of rows) {
    const email = emailAssignments.get(row.name)!;
    const roleName = roleAssignments.get(row.name)!;
    const role = rolesByName.get(roleName)!;
    const temporaryPassword = generateTemporaryPassword();
    const passwordHash = await bcrypt.hash(temporaryPassword, 10);

    const user = await userRepo.save(
      userRepo.create({
        email,
        passwordHash,
        roleId: role.id,
        role,
        status: UserStatus.PENDING_INVITE,
      }),
    );

    sequence += 1;
    const employeeCode = `ZC-${String(sequence).padStart(5, '0')}`;

    let profilePhotoUrl: string | undefined;
    if (row.imageFile) {
      const ext = row.imageFile.split('.').pop();
      const destName = `${employeeCode}.${ext}`;
      copyFileSync(
        join(SOURCE_DIR, 'avatars', row.imageFile),
        join(avatarsDir, destName),
      );
      profilePhotoUrl = `/uploads/avatars/${destName}`;
    }

    const department = departmentsByName.get(inferDepartment(row.jobTitle))!;
    const nameTokens = row.name.split(/\s+/);

    await employeeRepo.save(
      employeeRepo.create({
        userId: user.id,
        employeeCode,
        firstName: nameTokens[0],
        lastName: nameTokens.slice(1).join(' '),
        designation: row.jobTitle,
        departmentId: department.id,
        personalEmail: row.workEmail ?? undefined,
        phoneNumber: row.workPhone ?? undefined,
        dateOfBirth: row.birthday ?? undefined,
        joiningDate:
          row.contractStart ??
          KNOWN_JOINING_DATES[row.name] ??
          new Date().toISOString().slice(0, 10),
        employmentType:
          row.jobTitle === 'Intern'
            ? EmploymentType.INTERN
            : EmploymentType.FULL_TIME,
        employmentStatus: EmploymentStatus.ACTIVE,
        workMode:
          row.workLocationName === 'Remote'
            ? WorkMode.REMOTE
            : WorkMode.ON_SITE,
        profilePhotoUrl,
        skills: [],
        certifications: [],
      }),
    );

    created.push({ employeeCode, name: row.name, role: roleName, email, temporaryPassword });
  }

  console.log('\nImport complete. Credentials (share securely, temporary):\n');
  console.log(
    'Employee Code'.padEnd(15) +
      'Name'.padEnd(24) +
      'Role'.padEnd(14) +
      'Email'.padEnd(38) +
      'Temp Password',
  );
  for (const entry of created) {
    console.log(
      entry.employeeCode.padEnd(15) +
        entry.name.padEnd(24) +
        entry.role.padEnd(14) +
        entry.email.padEnd(38) +
        entry.temporaryPassword,
    );
  }

  console.log(
    '\nNote: this export has no "reports to" data, so no manager relationships were set. ' +
      'Assign reporting managers per person via Edit Employee.',
  );

  await app.close();
}

run().catch((error) => {
  console.error('Import failed:', error);
  process.exit(1);
});
