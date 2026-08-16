import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { getRepositoryToken } from '@nestjs/typeorm';
import * as bcrypt from 'bcryptjs';
import { Repository } from 'typeorm';
import { AppModule } from './app.module';
import { Permission } from './features/authentication/domain/entities/permission.entity';
import { Role } from './features/authentication/domain/entities/role.entity';
import { User } from './features/authentication/domain/entities/user.entity';
import { UserStatus } from './features/authentication/domain/enums/user-status.enum';
import { Department } from './features/departments/domain/entities/department.entity';
import { LeaveType } from './features/leave/domain/entities/leave-type.entity';
import { Team } from './features/teams/domain/entities/team.entity';

const DEFAULT_PERMISSIONS = [
  'users.manage',
  'users.impersonate',
  'employees.read',
  'employees.manage',
  'departments.manage',
  'teams.manage',
  'audit.viewAll',
  'notices.manage',
  'leave.manage',
  'roles.manage',
];

const DEFAULT_ROLES: { name: string; permissions: string[] }[] = [
  { name: 'Super Admin', permissions: [] }, // always granted every known permission, see below
  {
    name: 'HR/Manager',
    permissions: [
      'users.manage',
      'employees.read',
      'employees.manage',
      'departments.manage',
      'teams.manage',
      'notices.manage',
      'leave.manage',
    ],
  },
  { name: 'Team Lead', permissions: ['employees.read'] },
  { name: 'Employee', permissions: [] },
];

const SAMPLE_LEAVE_TYPES: {
  name: string;
  annualAllowanceDays: string;
  carryForwardLimitDays?: string;
  colorHex: string;
}[] = [
  { name: 'Annual Leave', annualAllowanceDays: '20.0', carryForwardLimitDays: '5.0', colorHex: '#00D5EE' },
  { name: 'Casual Leave', annualAllowanceDays: '10.0', colorHex: '#F59E0B' },
  { name: 'Sick Leave', annualAllowanceDays: '10.0', colorHex: '#DC2626' },
];

const SAMPLE_DEPARTMENTS: {
  name: string;
  description: string;
  teams: string[];
}[] = [
  {
    name: 'Engineering',
    description: 'Product engineering and platform development',
    teams: ['Platform', 'Web'],
  },
  {
    name: 'Human Resources',
    description: 'People operations and recruitment',
    teams: [],
  },
];

async function seed() {
  const app = await NestFactory.createApplicationContext(AppModule);

  const permissionRepo = app.get<Repository<Permission>>(
    getRepositoryToken(Permission),
  );
  const roleRepo = app.get<Repository<Role>>(getRepositoryToken(Role));
  const userRepo = app.get<Repository<User>>(getRepositoryToken(User));
  const departmentRepo = app.get<Repository<Department>>(
    getRepositoryToken(Department),
  );
  const teamRepo = app.get<Repository<Team>>(getRepositoryToken(Team));
  const leaveTypeRepo = app.get<Repository<LeaveType>>(
    getRepositoryToken(LeaveType),
  );
  const config = app.get(ConfigService);

  const permissionsByKey = new Map<string, Permission>();
  for (const key of DEFAULT_PERMISSIONS) {
    let permission = await permissionRepo.findOne({ where: { key } });
    permission ??= await permissionRepo.save(permissionRepo.create({ key }));
    permissionsByKey.set(key, permission);
  }
  const allPermissions = [...permissionsByKey.values()];

  for (const roleDef of DEFAULT_ROLES) {
    const grantedPermissions =
      roleDef.name === 'Super Admin'
        ? allPermissions
        : roleDef.permissions.map((key) => permissionsByKey.get(key)!);

    let role = await roleRepo.findOne({ where: { name: roleDef.name } });
    if (!role) {
      role = roleRepo.create({
        name: roleDef.name,
        isSystem: true,
        permissions: grantedPermissions,
      });
    } else {
      role.permissions = grantedPermissions;
    }
    await roleRepo.save(role);
    console.log(`Role ready: ${roleDef.name}`);
  }

  const superAdminEmail = config.get<string>('seed.superAdminEmail');
  const superAdminPassword = config.get<string>('seed.superAdminPassword');

  if (superAdminEmail && superAdminPassword) {
    const existing = await userRepo.findOne({
      where: { email: superAdminEmail },
    });
    if (!existing) {
      const superAdminRole = await roleRepo.findOneOrFail({
        where: { name: 'Super Admin' },
      });
      const passwordHash = await bcrypt.hash(superAdminPassword, 10);
      await userRepo.save(
        userRepo.create({
          email: superAdminEmail,
          passwordHash,
          roleId: superAdminRole.id,
          role: superAdminRole,
          status: UserStatus.ACTIVE,
        }),
      );
      console.log(`Created Super Admin user: ${superAdminEmail}`);
    } else {
      console.log(`Super Admin user already exists: ${superAdminEmail}`);
    }
  } else {
    console.log(
      'SEED_SUPER_ADMIN_EMAIL/PASSWORD not set — skipping Super Admin bootstrap.',
    );
  }

  for (const deptDef of SAMPLE_DEPARTMENTS) {
    let department = await departmentRepo.findOne({
      where: { name: deptDef.name },
    });
    department ??= await departmentRepo.save(
      departmentRepo.create({
        name: deptDef.name,
        description: deptDef.description,
      }),
    );
    console.log(`Department ready: ${deptDef.name}`);

    for (const teamName of deptDef.teams) {
      const existingTeam = await teamRepo.findOne({
        where: { name: teamName, departmentId: department.id },
      });
      if (!existingTeam) {
        await teamRepo.save(
          teamRepo.create({ name: teamName, departmentId: department.id }),
        );
        console.log(`  Team ready: ${teamName}`);
      }
    }
  }

  for (const typeDef of SAMPLE_LEAVE_TYPES) {
    const existing = await leaveTypeRepo.findOne({
      where: { name: typeDef.name },
    });
    if (!existing) {
      await leaveTypeRepo.save(leaveTypeRepo.create(typeDef));
      console.log(`Leave type ready: ${typeDef.name}`);
    }
  }

  await app.close();
}

seed().catch((error) => {
  console.error('Seed failed:', error);
  process.exit(1);
});
