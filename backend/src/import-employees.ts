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
import { generateTemporaryPassword } from './core/utils/generate-temporary-password.util';

// Source data extracted from the Odoo "hr.employee" export
// (Employee (hr.employee).xlsx, 26 rows, has Department/Manager columns).
// See scratchpad xlsx-inspect/inspect.js for how summary.json and images/
// were produced.
const SOURCE_DIR =
  'C:\\Users\\Zera\\AppData\\Local\\Temp\\claude\\C--Users-Zera-Desktop-Zera-ERP\\8d1aa31a-01f5-4952-aa7b-5444529e9984\\scratchpad\\xlsx-inspect';

interface SourceRow {
  name: string;
  phone: string | null;
  department: string;
  jobTitle: string;
  manager: string | null;
  hasAvatar: boolean;
  imageFile: string | null;
  imageBytes: number;
}

// Odoo's placeholder "no avatar" SVG icon is ~305 bytes; anything that small
// isn't a real photo.
const MIN_REAL_PHOTO_BYTES = 1000;

function inferRole(row: SourceRow, managerNames: Set<string>): string {
  if (/chief executive/i.test(row.jobTitle)) return 'Super Admin';
  if (/hr manager/i.test(row.jobTitle)) return 'HR/Manager';
  if (managerNames.has(row.name)) return 'Team Lead';
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
    readFileSync(join(SOURCE_DIR, 'summary.json'), 'utf-8'),
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

  // --- Wipe the existing employee roster before re-importing ---
  const existingEmployees = await employeeRepo.find();
  if (existingEmployees.length > 0) {
    const userIds = existingEmployees.map((e) => e.userId);
    const existingIds = existingEmployees.map((e) => e.id);
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

  // --- Departments ---
  const departmentNames = [
    ...new Set(
      rows.map((r) =>
        r.department === 'Managment' ? 'Management' : r.department,
      ),
    ),
  ];
  const departmentsByName = new Map<string, Department>();
  for (const name of departmentNames) {
    let dept = await departmentRepo.findOne({ where: { name } });
    dept ??= await departmentRepo.save(departmentRepo.create({ name }));
    departmentsByName.set(name, dept);
  }
  console.log(`Departments ready: ${departmentNames.join(', ')}`);

  const managerNames = new Set(
    rows.map((r) => r.manager).filter((m): m is string => !!m),
  );
  const roleAssignments = new Map(
    rows.map((r) => [r.name, inferRole(r, managerNames)]),
  );
  const emailAssignments = buildEmailAssignments(rows.map((r) => r.name));

  const rolesByName = new Map<string, Role>();
  for (const roleName of new Set(roleAssignments.values())) {
    const role = await roleRepo.findOneOrFail({ where: { name: roleName } });
    rolesByName.set(roleName, role);
  }

  const avatarsDir = join(__dirname, '..', 'uploads', 'avatars');
  mkdirSync(avatarsDir, { recursive: true });

  const employeesByName = new Map<
    string,
    {
      employee: Employee;
      email: string;
      temporaryPassword: string;
      role: string;
    }
  >();

  let sequence = 0;

  // --- Pass 1: create User + Employee for every row (no manager link yet) ---
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
    if (
      row.hasAvatar &&
      row.imageFile &&
      row.imageBytes >= MIN_REAL_PHOTO_BYTES
    ) {
      const ext = row.imageFile.split('.').pop();
      const destName = `${employeeCode}.${ext}`;
      copyFileSync(
        join(SOURCE_DIR, 'images', row.imageFile),
        join(avatarsDir, destName),
      );
      profilePhotoUrl = `/uploads/avatars/${destName}`;
    }

    const departmentName =
      row.department === 'Managment' ? 'Management' : row.department;
    const department = departmentsByName.get(departmentName)!;

    const employee = await employeeRepo.save(
      employeeRepo.create({
        userId: user.id,
        employeeCode,
        firstName: row.name.split(/\s+/)[0],
        lastName: row.name.split(/\s+/).slice(1).join(' '),
        designation: row.jobTitle,
        departmentId: department.id,
        phoneNumber: row.phone ?? undefined,
        joiningDate: new Date().toISOString().slice(0, 10),
        employmentType: EmploymentType.FULL_TIME,
        employmentStatus: EmploymentStatus.ACTIVE,
        profilePhotoUrl,
        skills: [],
        certifications: [],
      }),
    );

    employeesByName.set(row.name, {
      employee,
      email,
      temporaryPassword,
      role: roleName,
    });
  }

  // --- Pass 2: resolve "Manager" now that every employee exists ---
  for (const row of rows) {
    if (!row.manager) continue;
    const managerEntry = employeesByName.get(row.manager);
    const employeeEntry = employeesByName.get(row.name);
    if (!managerEntry || !employeeEntry) continue;
    employeeEntry.employee.reportingManagerId = managerEntry.employee.id;
    await employeeRepo.save(employeeEntry.employee);
  }

  console.log('\nImport complete. Credentials (share securely, temporary):\n');
  console.log(
    'Employee Code'.padEnd(15) +
      'Name'.padEnd(24) +
      'Role'.padEnd(14) +
      'Email'.padEnd(32) +
      'Temp Password',
  );
  for (const row of rows) {
    const entry = employeesByName.get(row.name)!;
    console.log(
      entry.employee.employeeCode.padEnd(15) +
        row.name.padEnd(24) +
        entry.role.padEnd(14) +
        entry.email.padEnd(32) +
        entry.temporaryPassword,
    );
  }

  await app.close();
}

run().catch((error) => {
  console.error('Import failed:', error);
  process.exit(1);
});
