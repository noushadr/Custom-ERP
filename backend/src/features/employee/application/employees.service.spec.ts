import {
  ConflictException,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { ChecklistsService } from '../../checklists/application/checklists.service';
import { ChecklistType } from '../../checklists/domain/enums/checklist-type.enum';
import { Role } from '../../authentication/domain/entities/role.entity';
import { User } from '../../authentication/domain/entities/user.entity';
import { UserStatus } from '../../authentication/domain/enums/user-status.enum';
import type { RoleRepository } from '../../authentication/domain/repositories/role-repository.interface';
import type { UserRepository } from '../../authentication/domain/repositories/user-repository.interface';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import { Asset } from '../domain/entities/asset.entity';
import { Employee } from '../domain/entities/employee.entity';
import { EmployeeAuditLog } from '../domain/entities/employee-audit-log.entity';
import { SalaryRecord } from '../domain/entities/salary-record.entity';
import { AssetStatus } from '../domain/enums/asset-status.enum';
import { EmploymentStatus } from '../domain/enums/employment-status.enum';
import { EmploymentType } from '../domain/enums/employment-type.enum';
import { WorkMode } from '../domain/enums/work-mode.enum';
import type { AssetRepository } from '../domain/repositories/asset-repository.interface';
import type { AuditLogRepository } from '../domain/repositories/audit-log-repository.interface';
import type { DocumentRepository } from '../domain/repositories/document-repository.interface';
import type { EmployeeRepository } from '../domain/repositories/employee-repository.interface';
import type { EducationRecordRepository } from '../domain/repositories/education-record-repository.interface';
import type { SalaryRecordRepository } from '../domain/repositories/salary-record-repository.interface';
import { EmployeesService } from './employees.service';

function buildViewer(overrides: Partial<JwtPayload> = {}): JwtPayload {
  return {
    sub: 'viewer-user-1',
    email: 'viewer@zeracreative.com',
    role: 'Employee',
    permissions: [],
    ...overrides,
  };
}

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

function buildSalaryRecord(overrides: Partial<SalaryRecord> = {}): SalaryRecord {
  return {
    id: 'salary-1',
    employeeId: 'employee-1',
    amount: '50000.00',
    effectiveDate: '2026-01-01',
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
    ...overrides,
  } as SalaryRecord;
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

/** ISO 'YYYY-MM-DD' joining date whose anniversary falls [offsetDays] from
 * today, [yearsAgo] years in the past — so both the day-window and the
 * years-of-service math can be controlled independently in a test. */
function isoJoiningDateAnniversaryInDays(
  yearsAgo: number,
  offsetDays: number,
): string {
  const target = new Date();
  target.setDate(target.getDate() + offsetDays);
  const month = String(target.getMonth() + 1).padStart(2, '0');
  const day = String(target.getDate()).padStart(2, '0');
  return `${target.getFullYear() - yearsAgo}-${month}-${day}`;
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
  let checklistsService: jest.Mocked<ChecklistsService>;

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
      findAllPaginated: jest.fn().mockResolvedValue({ items: [], total: 0 }),
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
      findById: jest.fn(),
      save: jest.fn(),
      remove: jest.fn(),
    };
    checklistsService = {
      createInstance: jest.fn().mockResolvedValue([]),
      getEmployeeChecklist: jest.fn(),
      setItemCompleted: jest.fn(),
    } as unknown as jest.Mocked<ChecklistsService>;

    service = new EmployeesService(
      employeeRepository,
      userRepository,
      roleRepository,
      documentRepository,
      auditLogRepository,
      salaryRecordRepository,
      educationRecordRepository,
      assetRepository,
      checklistsService,
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

    it('creates an onboarding checklist instance for the new employee', async () => {
      userRepository.findByEmail.mockResolvedValue(null);
      roleRepository.findByName.mockResolvedValue(buildRole());
      userRepository.save.mockImplementation(
        (user) =>
          Promise.resolve({ ...user, id: 'new-user-id' }) as Promise<User>,
      );
      employeeRepository.save.mockImplementation((employee) =>
        Promise.resolve({ ...employee, id: 'new-employee-id' }),
      );
      employeeRepository.findById.mockResolvedValue(
        buildEmployee({ id: 'new-employee-id', workMode: WorkMode.REMOTE }),
      );

      await service.invite(dto);

      expect(checklistsService.createInstance).toHaveBeenCalledWith(
        'new-employee-id',
        ChecklistType.ONBOARDING,
        WorkMode.REMOTE,
      );
    });

    it('saves the invited employee with the given work mode', async () => {
      userRepository.findByEmail.mockResolvedValue(null);
      roleRepository.findByName.mockResolvedValue(buildRole());
      userRepository.save.mockImplementation(
        (user) =>
          Promise.resolve({ ...user, id: 'new-user-id' }) as Promise<User>,
      );
      employeeRepository.save.mockImplementation((employee) =>
        Promise.resolve({ ...employee, id: 'new-employee-id' }),
      );
      employeeRepository.findById.mockResolvedValue(buildEmployee());

      await service.invite({ ...dto, workMode: WorkMode.REMOTE });

      expect(employeeRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ workMode: WorkMode.REMOTE }),
      );
    });

    it('defaults the work mode to on-site when not specified', async () => {
      userRepository.findByEmail.mockResolvedValue(null);
      roleRepository.findByName.mockResolvedValue(buildRole());
      userRepository.save.mockImplementation(
        (user) =>
          Promise.resolve({ ...user, id: 'new-user-id' }) as Promise<User>,
      );
      employeeRepository.save.mockImplementation((employee) =>
        Promise.resolve({ ...employee, id: 'new-employee-id' }),
      );
      employeeRepository.findById.mockResolvedValue(buildEmployee());

      await service.invite(dto);

      expect(employeeRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ workMode: WorkMode.ON_SITE }),
      );
    });

    it('uses a provided employeeCode instead of generating one, for imports that must keep a legacy code', async () => {
      userRepository.findByEmail.mockResolvedValue(null);
      roleRepository.findByName.mockResolvedValue(buildRole());
      userRepository.save.mockImplementation(
        (user) =>
          Promise.resolve({ ...user, id: 'new-user-id' }) as Promise<User>,
      );
      employeeRepository.save.mockImplementation((employee) =>
        Promise.resolve({ ...employee, id: 'new-employee-id' }),
      );
      employeeRepository.findById.mockResolvedValue(
        buildEmployee({ id: 'new-employee-id', employeeCode: 'ZC-002' }),
      );

      await service.invite({ ...dto, employeeCode: 'ZC-002' });

      expect(employeeRepository.count).not.toHaveBeenCalled();
      expect(employeeRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ employeeCode: 'ZC-002' }),
      );
    });
  });

  describe('update', () => {
    it('updates a plain field without touching the login email', async () => {
      const employee = buildEmployee();
      employeeRepository.findById
        .mockResolvedValueOnce(employee)
        .mockResolvedValueOnce({ ...employee, designation: 'Team Lead' });
      employeeRepository.save.mockResolvedValue(employee);

      await service.update(
        employee.id,
        { designation: 'Team Lead' },
        'actor-1',
      );

      expect(userRepository.findByEmail).not.toHaveBeenCalled();
      expect(userRepository.save).not.toHaveBeenCalled();
    });

    it("changes the employee's company email when it isn't taken", async () => {
      const employee = buildEmployee();
      employeeRepository.findById
        .mockResolvedValueOnce(employee)
        .mockResolvedValueOnce({
          ...employee,
          user: buildUser({ email: 'jane.smith@zeracreative.com' }),
        });
      employeeRepository.save.mockResolvedValue(employee);
      userRepository.findByEmail.mockResolvedValue(null);
      userRepository.findById.mockResolvedValue(buildUser());
      userRepository.save.mockResolvedValue(buildUser());

      const result = await service.update(
        employee.id,
        { companyEmail: 'jane.smith@zeracreative.com' },
        'actor-1',
      );

      expect(userRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ email: 'jane.smith@zeracreative.com' }),
      );
      expect(result.email).toBe('jane.smith@zeracreative.com');
      expect(auditLogRepository.saveMany).toHaveBeenCalledWith([
        expect.objectContaining({
          fieldLabel: 'Company Email',
          oldValue: 'jane.doe@zeracreative.com',
          newValue: 'jane.smith@zeracreative.com',
        }),
      ]);
    });

    it('throws when the requested company email already belongs to someone else', async () => {
      const employee = buildEmployee();
      employeeRepository.findById.mockResolvedValue(employee);
      userRepository.findByEmail.mockResolvedValue(
        buildUser({ id: 'someone-else' }),
      );

      await expect(
        service.update(
          employee.id,
          { companyEmail: 'taken@zeracreative.com' },
          'actor-1',
        ),
      ).rejects.toBeInstanceOf(ConflictException);
      expect(userRepository.save).not.toHaveBeenCalled();
    });

    it('is a no-op when the submitted company email matches the current one', async () => {
      const employee = buildEmployee();
      employeeRepository.findById
        .mockResolvedValueOnce(employee)
        .mockResolvedValueOnce(employee);
      employeeRepository.save.mockResolvedValue(employee);

      await service.update(
        employee.id,
        { companyEmail: employee.user.email },
        'actor-1',
      );

      expect(userRepository.findByEmail).not.toHaveBeenCalled();
      expect(userRepository.save).not.toHaveBeenCalled();
    });

    it('creates an offboarding checklist when employmentStatus moves from active to resigned', async () => {
      const employee = buildEmployee({
        employmentStatus: EmploymentStatus.ACTIVE,
        workMode: WorkMode.ON_SITE,
      });
      employeeRepository.findById
        .mockResolvedValueOnce(employee)
        .mockResolvedValueOnce({
          ...employee,
          employmentStatus: EmploymentStatus.RESIGNED,
        });
      employeeRepository.save.mockResolvedValue(employee);

      await service.update(
        employee.id,
        { employmentStatus: EmploymentStatus.RESIGNED },
        'actor-1',
      );

      expect(checklistsService.createInstance).toHaveBeenCalledWith(
        employee.id,
        ChecklistType.OFFBOARDING,
        WorkMode.ON_SITE,
      );
    });

    it('does not re-create an offboarding checklist on a later transition between leaving statuses', async () => {
      const employee = buildEmployee({
        employmentStatus: EmploymentStatus.NOTICE_PERIOD,
      });
      employeeRepository.findById
        .mockResolvedValueOnce(employee)
        .mockResolvedValueOnce({
          ...employee,
          employmentStatus: EmploymentStatus.RESIGNED,
        });
      employeeRepository.save.mockResolvedValue(employee);

      await service.update(
        employee.id,
        { employmentStatus: EmploymentStatus.RESIGNED },
        'actor-1',
      );

      expect(checklistsService.createInstance).not.toHaveBeenCalled();
    });

    it('does not touch the offboarding checklist when employmentStatus is unchanged', async () => {
      const employee = buildEmployee();
      employeeRepository.findById
        .mockResolvedValueOnce(employee)
        .mockResolvedValueOnce({ ...employee, designation: 'Team Lead' });
      employeeRepository.save.mockResolvedValue(employee);

      await service.update(employee.id, { designation: 'Team Lead' }, 'actor-1');

      expect(checklistsService.createInstance).not.toHaveBeenCalled();
    });
  });

  describe('findById', () => {
    it('throws NotFoundException when missing', async () => {
      employeeRepository.findById.mockResolvedValue(null);

      await expect(
        service.findById('missing', buildViewer({ permissions: ['employees.manage'] })),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('returns the mapped employee when found', async () => {
      employeeRepository.findById.mockResolvedValue(buildEmployee());

      const result = await service.findById(
        'employee-1',
        buildViewer({ permissions: ['employees.manage'] }),
      );

      expect(result.fullName).toBe('Jane Doe');
      expect(result.email).toBe('jane.doe@zeracreative.com');
    });

    it('strips financial and personal-contact fields for a viewer without employees.manage', async () => {
      employeeRepository.findById.mockResolvedValue(
        buildEmployee({
          bankName: 'Habib Bank',
          accountNumber: '1234567890',
          iban: 'PK00HABB0000001234567890',
          dateOfBirth: '1997-08-13',
          personalEmail: 'jane.personal@example.com',
          phoneNumber: '+92-300-1234567',
          address: '123 Street, Karachi',
          emergencyContactName: 'John Doe',
        }),
      );

      const result = await service.findById(
        'employee-1',
        buildViewer({ sub: 'someone-else', permissions: ['employees.read'] }),
      );

      expect(result.bankName).toBeNull();
      expect(result.accountNumber).toBeNull();
      expect(result.iban).toBeNull();
      expect(result.dateOfBirth).toBeNull();
      expect(result.personalEmail).toBeNull();
      expect(result.phoneNumber).toBeNull();
      expect(result.address).toBeNull();
      expect(result.emergencyContactName).toBeNull();
      // Directory-level fields remain visible.
      expect(result.fullName).toBe('Jane Doe');
    });

    it('still shows a viewer their own financial and personal-contact fields', async () => {
      employeeRepository.findById.mockResolvedValue(
        buildEmployee({ userId: 'user-1', bankName: 'Habib Bank' }),
      );

      const result = await service.findById(
        'employee-1',
        buildViewer({ sub: 'user-1', permissions: [] }),
      );

      expect(result.bankName).toBe('Habib Bank');
    });
  });

  describe('findAll', () => {
    it('strips financial and personal-contact fields for a viewer without employees.manage', async () => {
      employeeRepository.findAll.mockResolvedValue([
        buildEmployee({ id: 'employee-1', userId: 'user-1', bankName: 'Habib Bank' }),
        buildEmployee({ id: 'employee-2', userId: 'user-2', bankName: 'Meezan Bank' }),
      ]);

      const [first, second] = await service.findAll(
        buildViewer({ sub: 'someone-else', permissions: ['employees.read'] }),
      );

      expect(first.bankName).toBeNull();
      expect(second.bankName).toBeNull();
    });

    it('keeps every field for an employees.manage viewer', async () => {
      employeeRepository.findAll.mockResolvedValue([
        buildEmployee({ id: 'employee-1', userId: 'user-1', bankName: 'Habib Bank' }),
      ]);

      const [result] = await service.findAll(
        buildViewer({ permissions: ['employees.manage'] }),
      );

      expect(result.bankName).toBe('Habib Bank');
    });

    it("keeps the viewer's own record unstripped even without employees.manage", async () => {
      employeeRepository.findAll.mockResolvedValue([
        buildEmployee({ id: 'employee-1', userId: 'user-1', bankName: 'Habib Bank' }),
        buildEmployee({ id: 'employee-2', userId: 'user-2', bankName: 'Meezan Bank' }),
      ]);

      const [own, other] = await service.findAll(
        buildViewer({ sub: 'user-1', permissions: ['employees.read'] }),
      );

      expect(own.bankName).toBe('Habib Bank');
      expect(other.bankName).toBeNull();
    });
  });

  describe('getMyDirectReports', () => {
    it('throws NotFoundException when the caller has no employee profile', async () => {
      employeeRepository.findByUserId.mockResolvedValue(null);

      await expect(
        service.getMyDirectReports(buildViewer({ sub: 'user-1' })),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('returns the mapped direct reports for the caller', async () => {
      const manager = buildEmployee({ id: 'manager-1' });
      employeeRepository.findByUserId.mockResolvedValue(manager);
      employeeRepository.findByReportingManagerId.mockResolvedValue([
        buildEmployee({ id: 'report-1', firstName: 'Ravi' }),
      ]);

      const result = await service.getMyDirectReports(
        buildViewer({ sub: 'user-1', permissions: ['employees.manage'] }),
      );

      expect(employeeRepository.findByReportingManagerId).toHaveBeenCalledWith(
        'manager-1',
      );
      expect(result).toHaveLength(1);
      expect(result[0].fullName).toBe('Ravi Doe');
    });

    it("strips bank/personal fields from a report when the manager lacks employees.manage — regression: this endpoint previously returned every direct report's bank details, IBAN, DOB, and personal contact info completely unmasked to any manager (e.g. a Team Lead), since it skipped the same field-visibility check findAll/findById already apply", async () => {
      const manager = buildEmployee({ id: 'manager-1', userId: 'user-1' });
      employeeRepository.findByUserId.mockResolvedValue(manager);
      employeeRepository.findByReportingManagerId.mockResolvedValue([
        buildEmployee({
          id: 'report-1',
          userId: 'report-user-1',
          bankName: 'Meezan Bank',
          accountNumber: '12345',
          dateOfBirth: '1998-01-01',
        }),
      ]);

      const result = await service.getMyDirectReports(
        buildViewer({ sub: 'user-1', permissions: ['employees.read'] }),
      );

      expect(result[0].bankName).toBeNull();
      expect(result[0].accountNumber).toBeNull();
      expect(result[0].dateOfBirth).toBeNull();
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

    it('includes a birthday that recently passed, with a negative daysUntil', async () => {
      const employee = buildEmployee({
        id: 'employee-passed',
        dateOfBirth: isoDobInDays(-1),
      });
      employeeRepository.findAll.mockResolvedValue([employee]);

      const result = await service.getUpcomingBirthdays(7);

      expect(result.map((r) => r.employeeId)).toEqual(['employee-passed']);
      expect(result[0].daysUntil).toBe(-1);
    });

    it('excludes a birthday that passed further back than the recent window', async () => {
      const employee = buildEmployee({
        id: 'employee-long-passed',
        dateOfBirth: isoDobInDays(-10),
      });
      employeeRepository.findAll.mockResolvedValue([employee]);

      const result = await service.getUpcomingBirthdays(7);

      expect(result).toHaveLength(0);
    });

    it('sorts recently-passed birthdays before today and upcoming ones', async () => {
      const passed = buildEmployee({
        id: 'employee-passed',
        dateOfBirth: isoDobInDays(-3),
      });
      const today = buildEmployee({
        id: 'employee-today',
        dateOfBirth: isoDobInDays(0),
      });
      const upcoming = buildEmployee({
        id: 'employee-upcoming',
        dateOfBirth: isoDobInDays(2),
      });
      employeeRepository.findAll.mockResolvedValue([
        upcoming,
        today,
        passed,
      ]);

      const result = await service.getUpcomingBirthdays(7);

      expect(result.map((r) => r.employeeId)).toEqual([
        'employee-passed',
        'employee-today',
        'employee-upcoming',
      ]);
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

    it("excludes an employee whose employmentStatus isn't active", async () => {
      const onLeave = buildEmployee({
        id: 'employee-on-leave',
        employmentStatus: EmploymentStatus.ON_LEAVE,
        dateOfBirth: isoDobInDays(1),
      });
      const resigned = buildEmployee({
        id: 'employee-resigned',
        employmentStatus: EmploymentStatus.RESIGNED,
        dateOfBirth: isoDobInDays(1),
      });
      employeeRepository.findAll.mockResolvedValue([onLeave, resigned]);

      const result = await service.getUpcomingBirthdays(7);

      expect(result).toHaveLength(0);
    });
  });

  describe('getUpcomingWorkAnniversaries', () => {
    it('returns active employees within the window, soonest first', async () => {
      const soon = buildEmployee({
        id: 'employee-soon',
        firstName: 'Soon',
        joiningDate: isoJoiningDateAnniversaryInDays(2, 3),
      });
      const soonest = buildEmployee({
        id: 'employee-soonest',
        firstName: 'Soonest',
        joiningDate: isoJoiningDateAnniversaryInDays(5, 1),
      });
      const tooFarAway = buildEmployee({
        id: 'employee-far',
        firstName: 'Far',
        joiningDate: isoJoiningDateAnniversaryInDays(1, 30),
      });
      employeeRepository.findAll.mockResolvedValue([soon, soonest, tooFarAway]);

      const result = await service.getUpcomingWorkAnniversaries(7);

      expect(result.map((r) => r.employeeId)).toEqual([
        'employee-soonest',
        'employee-soon',
      ]);
      expect(result[0]).toMatchObject({ daysUntil: 1, yearsOfService: 5 });
      expect(result[1]).toMatchObject({ daysUntil: 3, yearsOfService: 2 });
    });

    it('includes an anniversary that recently passed, with a negative daysUntil', async () => {
      const employee = buildEmployee({
        id: 'employee-passed',
        joiningDate: isoJoiningDateAnniversaryInDays(1, -1),
      });
      employeeRepository.findAll.mockResolvedValue([employee]);

      const result = await service.getUpcomingWorkAnniversaries(7);

      expect(result.map((r) => r.employeeId)).toEqual(['employee-passed']);
      expect(result[0].daysUntil).toBe(-1);
    });

    it('excludes an anniversary that passed further back than the recent window', async () => {
      const employee = buildEmployee({
        id: 'employee-long-passed',
        joiningDate: isoJoiningDateAnniversaryInDays(1, -10),
      });
      employeeRepository.findAll.mockResolvedValue([employee]);

      const result = await service.getUpcomingWorkAnniversaries(7);

      expect(result).toHaveLength(0);
    });

    it('sorts recently-passed anniversaries before today and upcoming ones', async () => {
      const passed = buildEmployee({
        id: 'employee-passed',
        joiningDate: isoJoiningDateAnniversaryInDays(1, -3),
      });
      const today = buildEmployee({
        id: 'employee-today',
        joiningDate: isoJoiningDateAnniversaryInDays(2, 0),
      });
      const upcoming = buildEmployee({
        id: 'employee-upcoming',
        joiningDate: isoJoiningDateAnniversaryInDays(3, 2),
      });
      employeeRepository.findAll.mockResolvedValue([upcoming, today, passed]);

      const result = await service.getUpcomingWorkAnniversaries(7);

      expect(result.map((r) => r.employeeId)).toEqual([
        'employee-passed',
        'employee-today',
        'employee-upcoming',
      ]);
    });

    it('includes an anniversary that falls today', async () => {
      const employee = buildEmployee({
        id: 'employee-today',
        joiningDate: isoJoiningDateAnniversaryInDays(4, 0),
      });
      employeeRepository.findAll.mockResolvedValue([employee]);

      const result = await service.getUpcomingWorkAnniversaries(7);

      expect(result.map((r) => r.employeeId)).toEqual(['employee-today']);
      expect(result[0]).toMatchObject({ daysUntil: 0, yearsOfService: 4 });
    });

    it('excludes an employee who joined less than a year ago', async () => {
      const employee = buildEmployee({
        id: 'employee-new',
        joiningDate: isoJoiningDateAnniversaryInDays(0, 1),
      });
      employeeRepository.findAll.mockResolvedValue([employee]);

      const result = await service.getUpcomingWorkAnniversaries(7);

      expect(result).toHaveLength(0);
    });

    it("excludes an employee whose employmentStatus isn't active", async () => {
      const terminated = buildEmployee({
        id: 'employee-terminated',
        employmentStatus: EmploymentStatus.TERMINATED,
        joiningDate: isoJoiningDateAnniversaryInDays(3, 1),
      });
      employeeRepository.findAll.mockResolvedValue([terminated]);

      const result = await service.getUpcomingWorkAnniversaries(7);

      expect(result).toHaveLength(0);
    });
  });

  describe('getPayrollSummary', () => {
    function mockSalaryByEmployee(amounts: Record<string, string[]>) {
      salaryRecordRepository.findByEmployeeId.mockImplementation(
        async (employeeId: string) =>
          (amounts[employeeId] ?? []).map((amount, index) =>
            buildSalaryRecord({
              id: `${employeeId}-salary-${index}`,
              employeeId,
              amount,
            }),
          ),
      );
    }

    it("sums each active employee's current (most recent) salary", async () => {
      employeeRepository.findAll.mockResolvedValue([
        buildEmployee({ id: 'employee-1' }),
        buildEmployee({ id: 'employee-2' }),
      ]);
      // Only the LAST amount per employee (the current salary) should count.
      mockSalaryByEmployee({
        'employee-1': ['50000.00', '60000.00'],
        'employee-2': ['40000.00'],
      });

      const result = await service.getPayrollSummary();

      expect(result.totalMonthlyPayroll).toBe(100000);
    });

    it('excludes employees whose employmentStatus is not active', async () => {
      employeeRepository.findAll.mockResolvedValue([
        buildEmployee({ id: 'employee-active' }),
        buildEmployee({
          id: 'employee-terminated',
          employmentStatus: EmploymentStatus.TERMINATED,
        }),
      ]);
      mockSalaryByEmployee({
        'employee-active': ['50000.00'],
        'employee-terminated': ['999999.00'],
      });

      const result = await service.getPayrollSummary();

      expect(result.totalMonthlyPayroll).toBe(50000);
      expect(result.activeEmployeeCount).toBe(1);
      expect(salaryRecordRepository.findByEmployeeId).not.toHaveBeenCalledWith(
        'employee-terminated',
      );
    });

    it('treats an active employee with no salary records as contributing zero', async () => {
      employeeRepository.findAll.mockResolvedValue([
        buildEmployee({ id: 'employee-1' }),
      ]);
      salaryRecordRepository.findByEmployeeId.mockResolvedValue([]);

      const result = await service.getPayrollSummary();

      expect(result.totalMonthlyPayroll).toBe(0);
    });

    it('spreads the monthly total across the days in the current calendar month', async () => {
      employeeRepository.findAll.mockResolvedValue([
        buildEmployee({ id: 'employee-1' }),
      ]);
      mockSalaryByEmployee({ 'employee-1': ['62000.00'] });
      const now = new Date();
      const daysInMonth = new Date(
        now.getFullYear(),
        now.getMonth() + 1,
        0,
      ).getDate();

      const result = await service.getPayrollSummary();

      expect(result.dailyPayroll).toBeCloseTo(62000 / daysInMonth);
    });
  });

  describe('getSalaryAsOf', () => {
    it('returns the latest record whose effectiveDate is on or before the given date', async () => {
      salaryRecordRepository.findByEmployeeId.mockResolvedValue([
        buildSalaryRecord({ amount: '40000.00', effectiveDate: '2025-01-01' }),
        buildSalaryRecord({ amount: '50000.00', effectiveDate: '2026-01-01' }),
        buildSalaryRecord({ amount: '60000.00', effectiveDate: '2026-12-01' }),
      ]);

      const result = await service.getSalaryAsOf('employee-1', '2026-08-31');

      expect(result).toBe(50000);
    });

    it('returns 0 when no record has taken effect by that date', async () => {
      salaryRecordRepository.findByEmployeeId.mockResolvedValue([
        buildSalaryRecord({ amount: '50000.00', effectiveDate: '2027-01-01' }),
      ]);

      const result = await service.getSalaryAsOf('employee-1', '2026-08-31');

      expect(result).toBe(0);
    });

    it('returns 0 for an employee with no salary records at all', async () => {
      salaryRecordRepository.findByEmployeeId.mockResolvedValue([]);

      const result = await service.getSalaryAsOf('employee-1', '2026-08-31');

      expect(result).toBe(0);
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

  describe('updateMyPhoto', () => {
    it('throws NotFoundException when the caller has no employee profile', async () => {
      employeeRepository.findByUserId.mockResolvedValue(null);

      await expect(
        service.updateMyPhoto('user-1', {
          filename: 'photo.jpg',
        } as Express.Multer.File),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it("updates the caller's own photo", async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      employeeRepository.save.mockImplementation((employee) =>
        Promise.resolve(employee),
      );
      employeeRepository.findById.mockResolvedValue(
        buildEmployee({ profilePhotoUrl: '/uploads/avatars/photo.jpg' }),
      );

      const result = await service.updateMyPhoto('user-1', {
        filename: 'photo.jpg',
      } as Express.Multer.File);

      expect(employeeRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          profilePhotoUrl: '/uploads/avatars/photo.jpg',
        }),
      );
      expect(result.profilePhotoUrl).toBe('/uploads/avatars/photo.jpg');
    });
  });

  describe('updatePhoto', () => {
    it('throws NotFoundException when the employee does not exist', async () => {
      employeeRepository.findById.mockResolvedValue(null);

      await expect(
        service.updatePhoto('employee-1', {
          filename: 'photo.jpg',
        } as Express.Multer.File),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it("updates another employee's photo, for HR/Admin", async () => {
      employeeRepository.findById
        .mockResolvedValueOnce(buildEmployee())
        .mockResolvedValueOnce(
          buildEmployee({ profilePhotoUrl: '/uploads/avatars/photo.jpg' }),
        );
      employeeRepository.save.mockImplementation((employee) =>
        Promise.resolve(employee),
      );

      const result = await service.updatePhoto('employee-1', {
        filename: 'photo.jpg',
      } as Express.Multer.File);

      expect(employeeRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          profilePhotoUrl: '/uploads/avatars/photo.jpg',
        }),
      );
      expect(result.profilePhotoUrl).toBe('/uploads/avatars/photo.jpg');
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
        { name: 'Dell Laptop', value: 150000 },
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

  describe('deleteAsset', () => {
    it('throws NotFoundException when the asset is not assigned to that employee', async () => {
      assetRepository.findById.mockResolvedValue(
        buildAsset({ assignedEmployeeId: 'someone-else' }),
      );

      await expect(
        service.deleteAsset('employee-1', 'asset-1', 'user-1'),
      ).rejects.toBeInstanceOf(NotFoundException);
      expect(assetRepository.remove).not.toHaveBeenCalled();
    });

    it('permanently removes the asset and records an audit entry', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      const asset = buildAsset({
        status: AssetStatus.ASSIGNED,
        assignedEmployeeId: 'employee-1',
        assignedAt: new Date('2026-01-01'),
      });
      assetRepository.findById.mockResolvedValue(asset);

      await service.deleteAsset('employee-1', 'asset-1', 'user-1');

      expect(assetRepository.remove).toHaveBeenCalledWith(asset);
      expect(auditLogRepository.saveMany).toHaveBeenCalledWith([
        expect.objectContaining({ fieldLabel: 'Assets' }),
      ]);
    });
  });

  describe('getCompanyAuditLog', () => {
    it('defaults to page 1 with a limit of 10 and no search', async () => {
      auditLogRepository.findAllPaginated.mockResolvedValue({
        items: [],
        total: 0,
      });

      const result = await service.getCompanyAuditLog({});

      expect(auditLogRepository.findAllPaginated).toHaveBeenCalledWith({
        page: 1,
        limit: 10,
        search: undefined,
      });
      expect(result).toEqual({ items: [], total: 0, page: 1, limit: 10 });
    });

    it('passes through an explicit page and limit', async () => {
      auditLogRepository.findAllPaginated.mockResolvedValue({
        items: [],
        total: 25,
      });

      const result = await service.getCompanyAuditLog({ page: 3, limit: 5 });

      expect(auditLogRepository.findAllPaginated).toHaveBeenCalledWith({
        page: 3,
        limit: 5,
        search: undefined,
      });
      expect(result.total).toBe(25);
    });

    it('trims and forwards the search term, dropping it when blank', async () => {
      auditLogRepository.findAllPaginated.mockResolvedValue({
        items: [],
        total: 0,
      });

      await service.getCompanyAuditLog({ search: '  Amna  ' });

      expect(auditLogRepository.findAllPaginated).toHaveBeenCalledWith({
        page: 1,
        limit: 10,
        search: 'Amna',
      });

      await service.getCompanyAuditLog({ search: '   ' });

      expect(auditLogRepository.findAllPaginated).toHaveBeenLastCalledWith({
        page: 1,
        limit: 10,
        search: undefined,
      });
    });

    it('maps returned entries to the response shape', async () => {
      auditLogRepository.findAllPaginated.mockResolvedValue({
        items: [
          {
            id: 'log-1',
            employeeId: 'employee-1',
            employee: buildEmployee({ firstName: 'Jane', lastName: 'Doe' }),
            actorUserId: 'user-1',
            actorName: 'HR Admin',
            fieldLabel: 'Phone Number',
            oldValue: '123',
            newValue: '456',
            createdAt: new Date('2026-01-01'),
          } as EmployeeAuditLog,
        ],
        total: 1,
      });

      const result = await service.getCompanyAuditLog({});

      expect(result.items).toEqual([
        expect.objectContaining({
          id: 'log-1',
          employeeName: 'Jane Doe',
          fieldLabel: 'Phone Number',
        }),
      ]);
    });
  });
});
