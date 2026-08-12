import {
  ConflictException,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Role } from '../../authentication/domain/entities/role.entity';
import { User } from '../../authentication/domain/entities/user.entity';
import { UserStatus } from '../../authentication/domain/enums/user-status.enum';
import type { RoleRepository } from '../../authentication/domain/repositories/role-repository.interface';
import type { UserRepository } from '../../authentication/domain/repositories/user-repository.interface';
import { Asset } from '../domain/entities/asset.entity';
import { Employee } from '../domain/entities/employee.entity';
import { AssetStatus } from '../domain/enums/asset-status.enum';
import { EmploymentStatus } from '../domain/enums/employment-status.enum';
import { EmploymentType } from '../domain/enums/employment-type.enum';
import type { AssetRepository } from '../domain/repositories/asset-repository.interface';
import type { AuditLogRepository } from '../domain/repositories/audit-log-repository.interface';
import type { DocumentRepository } from '../domain/repositories/document-repository.interface';
import type { EmployeeRepository } from '../domain/repositories/employee-repository.interface';
import type { EducationRecordRepository } from '../domain/repositories/education-record-repository.interface';
import type { SalaryRecordRepository } from '../domain/repositories/salary-record-repository.interface';
import { EmployeesService } from './employees.service';

function buildAsset(overrides: Partial<Asset> = {}): Asset {
  return {
    id: 'asset-1',
    name: 'Dell Laptop',
    status: AssetStatus.AVAILABLE,
    assignedEmployeeId: null,
    assignedAt: null,
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
    ...overrides,
  } as Asset;
}

jest.mock('bcryptjs');

/** ISO 'YYYY-MM-DD' with an arbitrary birth year but the month/day that
 * falls [offsetDays] from today — the service only compares month/day. */
function isoDobInDays(offsetDays: number): string {
  const target = new Date();
  target.setDate(target.getDate() + offsetDays);
  const month = String(target.getMonth() + 1).padStart(2, '0');
  const day = String(target.getDate()).padStart(2, '0');
  return `1990-${month}-${day}`;
}

function buildRole(name = 'Employee'): Role {
  return { id: `role-${name}`, name, permissions: [] } as Role;
}

function buildUser(overrides: Partial<User> = {}): User {
  return {
    id: 'user-1',
    email: 'jane.doe@zeracreative.com',
    passwordHash: 'hash',
    roleId: 'role-Employee',
    role: buildRole(),
    status: UserStatus.PENDING_INVITE,
    ...overrides,
  } as User;
}

function buildEmployee(overrides: Partial<Employee> = {}): Employee {
  return {
    id: 'employee-1',
    employeeCode: 'ZC-00001',
    userId: 'user-1',
    user: buildUser({ status: UserStatus.ACTIVE }),
    firstName: 'Jane',
    lastName: 'Doe',
    employmentType: EmploymentType.FULL_TIME,
    employmentStatus: EmploymentStatus.ACTIVE,
    joiningDate: '2026-01-01',
    skills: [],
    certifications: [],
    ...overrides,
  } as Employee;
}

describe('EmployeesService', () => {
  let service: EmployeesService;
  let employeeRepository: jest.Mocked<EmployeeRepository>;
  let userRepository: jest.Mocked<UserRepository>;
  let roleRepository: jest.Mocked<RoleRepository>;
  let documentRepository: jest.Mocked<DocumentRepository>;
  let auditLogRepository: jest.Mocked<AuditLogRepository>;
  let salaryRecordRepository: jest.Mocked<SalaryRecordRepository>;
  let educationRecordRepository: jest.Mocked<EducationRecordRepository>;
  let assetRepository: jest.Mocked<AssetRepository>;

  beforeEach(() => {
    employeeRepository = {
      findAll: jest.fn(),
      findById: jest.fn(),
      findByUserId: jest.fn(),
      findByReportingManagerId: jest.fn(),
      count: jest.fn(),
      save: jest.fn(),
    };
    userRepository = {
      findByEmail: jest.fn(),
      findById: jest.fn(),
      findAll: jest.fn(),
      save: jest.fn(),
    };
    roleRepository = {
      findByName: jest.fn(),
    };
    documentRepository = {
      findByEmployeeId: jest.fn(),
      findById: jest.fn(),
      save: jest.fn(),
      remove: jest.fn(),
    };
    auditLogRepository = {
      findByEmployeeId: jest.fn(),
      findAll: jest.fn(),
      saveMany: jest.fn().mockResolvedValue([]),
    };
    salaryRecordRepository = {
      findByEmployeeId: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      save: jest.fn(),
      remove: jest.fn(),
    };
    educationRecordRepository = {
      findByEmployeeId: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      save: jest.fn(),
      remove: jest.fn(),
    };
    assetRepository = {
      findByAssignedEmployeeId: jest.fn().mockResolvedValue([]),
      findAvailable: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      save: jest.fn(),
    };

    service = new EmployeesService(
      employeeRepository,
      userRepository,
      roleRepository,
      documentRepository,
      auditLogRepository,
      salaryRecordRepository,
      educationRecordRepository,
      assetRepository,
    );

    (bcrypt.hash as jest.Mock).mockResolvedValue('hashed-temp-password');
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('invite', () => {
    const dto = {
      companyEmail: 'new.hire@zeracreative.com',
      firstName: 'New',
      lastName: 'Hire',
    };

    it('throws when a user already exists for that email', async () => {
      userRepository.findByEmail.mockResolvedValue(buildUser());

      await expect(service.invite(dto)).rejects.toBeInstanceOf(
        ConflictException,
      );
    });

    it('throws when the default Employee role is not seeded', async () => {
      userRepository.findByEmail.mockResolvedValue(null);
      roleRepository.findByName.mockResolvedValue(null);

      await expect(service.invite(dto)).rejects.toBeInstanceOf(
        InternalServerErrorException,
      );
    });

    it('creates a pending user and employee, returning a temporary password', async () => {
      userRepository.findByEmail.mockResolvedValue(null);
      roleRepository.findByName.mockResolvedValue(buildRole());
      userRepository.save.mockImplementation(
        (user) =>
          Promise.resolve({ ...user, id: 'new-user-id' }) as Promise<User>,
      );
      employeeRepository.count.mockResolvedValue(4);
      employeeRepository.save.mockImplementation((employee) =>
        Promise.resolve({ ...employee, id: 'new-employee-id' }),
      );
      employeeRepository.findById.mockResolvedValue(
        buildEmployee({ id: 'new-employee-id', employeeCode: 'ZC-00005' }),
      );

      const result = await service.invite(dto);

      expect(userRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          email: dto.companyEmail,
          status: UserStatus.PENDING_INVITE,
        }),
      );
      expect(employeeRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ userId: 'new-user-id' }),
      );
      expect(result.temporaryPassword).toHaveLength(12);
      expect(result.employee.employeeCode).toBe('ZC-00005');
    });
  });

  describe('findById', () => {
    it('throws NotFoundException when missing', async () => {
      employeeRepository.findById.mockResolvedValue(null);

      await expect(service.findById('missing')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('returns the mapped employee when found', async () => {
      employeeRepository.findById.mockResolvedValue(buildEmployee());

      const result = await service.findById('employee-1');

      expect(result.fullName).toBe('Jane Doe');
      expect(result.email).toBe('jane.doe@zeracreative.com');
    });
  });

  describe('getMyDirectReports', () => {
    it('throws NotFoundException when the caller has no employee profile', async () => {
      employeeRepository.findByUserId.mockResolvedValue(null);

      await expect(service.getMyDirectReports('user-1')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('returns the mapped direct reports for the caller', async () => {
      const manager = buildEmployee({ id: 'manager-1' });
      employeeRepository.findByUserId.mockResolvedValue(manager);
      employeeRepository.findByReportingManagerId.mockResolvedValue([
        buildEmployee({ id: 'report-1', firstName: 'Ravi' }),
      ]);

      const result = await service.getMyDirectReports('user-1');

      expect(employeeRepository.findByReportingManagerId).toHaveBeenCalledWith(
        'manager-1',
      );
      expect(result).toHaveLength(1);
      expect(result[0].fullName).toBe('Ravi Doe');
    });
  });

  describe('getUpcomingBirthdays', () => {
    it('returns employees within the window, soonest first', async () => {
      const soon = buildEmployee({
        id: 'employee-soon',
        firstName: 'Soon',
        dateOfBirth: isoDobInDays(3),
      });
      const soonest = buildEmployee({
        id: 'employee-soonest',
        firstName: 'Soonest',
        dateOfBirth: isoDobInDays(1),
      });
      const tooFarAway = buildEmployee({
        id: 'employee-far',
        firstName: 'Far',
        dateOfBirth: isoDobInDays(30),
      });
      const noDob = buildEmployee({
        id: 'employee-no-dob',
        firstName: 'NoDob',
        dateOfBirth: undefined,
      });
      employeeRepository.findAll.mockResolvedValue([
        soon,
        soonest,
        tooFarAway,
        noDob,
      ]);

      const result = await service.getUpcomingBirthdays(7);

      expect(result.map((r) => r.employeeId)).toEqual([
        'employee-soonest',
        'employee-soon',
      ]);
      expect(result[0].daysUntil).toBe(1);
      expect(result[1].daysUntil).toBe(3);
    });

    it('wraps a birthday that already passed this year to next year', async () => {
      // "Passed a moment ago" (-1 day) should resolve to the occurrence
      // ~364-366 days out next year, not a negative/near-zero count.
      const employee = buildEmployee({
        id: 'employee-passed',
        dateOfBirth: isoDobInDays(-1),
      });
      employeeRepository.findAll.mockResolvedValue([employee]);

      const result = await service.getUpcomingBirthdays(7);

      expect(result).toHaveLength(0);
    });

    it('includes a birthday that falls today', async () => {
      const employee = buildEmployee({
        id: 'employee-today',
        dateOfBirth: isoDobInDays(0),
      });
      employeeRepository.findAll.mockResolvedValue([employee]);

      const result = await service.getUpcomingBirthdays(7);

      expect(result.map((r) => r.employeeId)).toEqual(['employee-today']);
      expect(result[0].daysUntil).toBe(0);
    });
  });

  describe('updateSelf', () => {
    it('throws NotFoundException when the caller has no employee profile', async () => {
      employeeRepository.findByUserId.mockResolvedValue(null);

      await expect(
        service.updateSelf('user-1', { phoneNumber: '123' }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('merges permitted fields and returns the refreshed profile', async () => {
      const existing = buildEmployee();
      employeeRepository.findByUserId.mockResolvedValue(existing);
      employeeRepository.save.mockResolvedValue(existing);
      employeeRepository.findById.mockResolvedValue(
        buildEmployee({ phoneNumber: '+1234567890' }),
      );

      const result = await service.updateSelf('user-1', {
        phoneNumber: '+1234567890',
      });

      expect(employeeRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ phoneNumber: '+1234567890' }),
      );
      expect(result.phoneNumber).toBe('+1234567890');
    });
  });

  describe('previewProfileChanges', () => {
    it('throws NotFoundException when the employee does not exist', async () => {
      employeeRepository.findById.mockResolvedValue(null);

      await expect(
        service.previewProfileChanges('employee-1', { phoneNumber: '123' }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('diffs the proposed change without saving anything', async () => {
      employeeRepository.findById.mockResolvedValue(
        buildEmployee({ phoneNumber: '111' }),
      );

      const diffs = await service.previewProfileChanges('employee-1', {
        phoneNumber: '222',
      });

      expect(diffs).toEqual([
        { fieldLabel: 'Phone Number', oldValue: '111', newValue: '222' },
      ]);
      expect(employeeRepository.save).not.toHaveBeenCalled();
    });
  });

  describe('applyApprovedProfileChange', () => {
    it('throws NotFoundException when the employee does not exist', async () => {
      employeeRepository.findById.mockResolvedValue(null);

      await expect(
        service.applyApprovedProfileChange('employee-1', {
          phoneNumber: '123',
        }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('applies the change and records an audit entry attributed to the employee', async () => {
      const existing = buildEmployee();
      employeeRepository.findById
        .mockResolvedValueOnce(existing)
        .mockResolvedValueOnce(buildEmployee({ phoneNumber: '+1234567890' }));
      employeeRepository.save.mockResolvedValue(existing);

      await service.applyApprovedProfileChange('employee-1', {
        phoneNumber: '+1234567890',
      });

      expect(employeeRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ phoneNumber: '+1234567890' }),
      );
      expect(auditLogRepository.saveMany).toHaveBeenCalledWith([
        expect.objectContaining({
          actorUserId: 'user-1',
          actorName: 'Jane Doe',
          fieldLabel: 'Phone Number',
          newValue: '+1234567890',
        }),
      ]);
    });
  });

  describe('getMyAssets', () => {
    it('throws NotFoundException when the caller has no employee profile', async () => {
      employeeRepository.findByUserId.mockResolvedValue(null);

      await expect(service.getMyAssets('user-1')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it("returns the caller's assigned assets", async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      employeeRepository.findById.mockResolvedValue(buildEmployee());
      assetRepository.findByAssignedEmployeeId.mockResolvedValue([
        buildAsset({ status: AssetStatus.ASSIGNED, assignedEmployeeId: 'employee-1' }),
      ]);

      const result = await service.getMyAssets('user-1');

      expect(result).toHaveLength(1);
      expect(result[0].status).toBe(AssetStatus.ASSIGNED);
    });
  });

  describe('createAndAssignAsset', () => {
    it('creates a new asset already assigned to the employee', async () => {
      employeeRepository.findById.mockResolvedValue(buildEmployee());
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      assetRepository.save.mockImplementation((asset) =>
        Promise.resolve({ ...asset, id: 'new-asset-id' } as Asset),
      );

      const result = await service.createAndAssignAsset(
        'employee-1',
        { name: 'Dell Laptop', serialNumber: 'SN-1' },
        'user-1',
      );

      expect(assetRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'Dell Laptop',
          status: AssetStatus.ASSIGNED,
          assignedEmployeeId: 'employee-1',
        }),
      );
      expect(result.status).toBe(AssetStatus.ASSIGNED);
      expect(auditLogRepository.saveMany).toHaveBeenCalledWith([
        expect.objectContaining({ fieldLabel: 'Assets' }),
      ]);
    });
  });

  describe('assignExistingAsset', () => {
    it('throws ConflictException when the asset is not available', async () => {
      employeeRepository.findById.mockResolvedValue(buildEmployee());
      assetRepository.findById.mockResolvedValue(
        buildAsset({ status: AssetStatus.ASSIGNED, assignedEmployeeId: 'someone-else' }),
      );

      await expect(
        service.assignExistingAsset('employee-1', 'asset-1', 'user-1'),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('assigns an available asset to the employee', async () => {
      employeeRepository.findById.mockResolvedValue(buildEmployee());
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      assetRepository.findById.mockResolvedValue(
        buildAsset({ status: AssetStatus.AVAILABLE }),
      );
      assetRepository.save.mockImplementation((asset) =>
        Promise.resolve(asset),
      );

      const result = await service.assignExistingAsset(
        'employee-1',
        'asset-1',
        'user-1',
      );

      expect(result.assignedEmployeeId).toBe('employee-1');
      expect(result.status).toBe(AssetStatus.ASSIGNED);
    });
  });

  describe('updateAsset', () => {
    it('throws NotFoundException when the asset is not assigned to that employee', async () => {
      assetRepository.findById.mockResolvedValue(
        buildAsset({ assignedEmployeeId: 'someone-else' }),
      );

      await expect(
        service.updateAsset('employee-1', 'asset-1', { name: 'New name' }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('updates the asset details', async () => {
      assetRepository.findById.mockResolvedValue(
        buildAsset({ assignedEmployeeId: 'employee-1' }),
      );
      assetRepository.save.mockImplementation((asset) =>
        Promise.resolve(asset),
      );

      const result = await service.updateAsset('employee-1', 'asset-1', {
        name: 'Updated name',
      });

      expect(result.name).toBe('Updated name');
    });
  });

  describe('unassignAsset', () => {
    it('clears the assignment and records an audit entry', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      assetRepository.findById.mockResolvedValue(
        buildAsset({
          status: AssetStatus.ASSIGNED,
          assignedEmployeeId: 'employee-1',
          assignedAt: new Date('2026-01-01'),
        }),
      );
      assetRepository.save.mockImplementation((asset) =>
        Promise.resolve(asset),
      );

      await service.unassignAsset('employee-1', 'asset-1', 'user-1');

      expect(assetRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          status: AssetStatus.AVAILABLE,
          assignedEmployeeId: null,
          assignedAt: null,
        }),
      );
      expect(auditLogRepository.saveMany).toHaveBeenCalledWith([
        expect.objectContaining({ fieldLabel: 'Assets' }),
      ]);
    });
  });
});
