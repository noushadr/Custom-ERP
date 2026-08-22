import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import type { RolesService } from '../../authentication/application/roles.service';
import type { UserRepository } from '../../authentication/domain/repositories/user-repository.interface';
import { Department } from '../../departments/domain/entities/department.entity';
import type { DepartmentRepository } from '../../departments/domain/repositories/department-repository.interface';
import { Employee } from '../../employee/domain/entities/employee.entity';
import { EmploymentStatus } from '../../employee/domain/enums/employment-status.enum';
import type { EmployeeRepository } from '../../employee/domain/repositories/employee-repository.interface';
import type { HolidaysService } from '../../holidays/application/holidays.service';
import type { NotificationsService } from '../../notifications/application/notifications.service';
import { LeaveBalance } from '../domain/entities/leave-balance.entity';
import { LeaveBalanceAdjustment } from '../domain/entities/leave-balance-adjustment.entity';
import { LeaveRequest } from '../domain/entities/leave-request.entity';
import { LeaveType } from '../domain/entities/leave-type.entity';
import { LeaveRequestStatus } from '../domain/enums/leave-request-status.enum';
import type { LeaveBalanceAdjustmentRepository } from '../domain/repositories/leave-balance-adjustment-repository.interface';
import type { LeaveBalanceRepository } from '../domain/repositories/leave-balance-repository.interface';
import type { LeaveRequestRepository } from '../domain/repositories/leave-request-repository.interface';
import type { LeaveTypeRepository } from '../domain/repositories/leave-type-repository.interface';
import { LeaveService } from './leave.service';

function buildEmployee(overrides: Partial<Employee> = {}): Employee {
  return {
    id: 'employee-1',
    firstName: 'Jane',
    lastName: 'Doe',
    departmentId: 'dept-1',
    employmentStatus: EmploymentStatus.ACTIVE,
    profilePhotoUrl: undefined,
    ...overrides,
  } as Employee;
}

function buildDepartment(overrides: Partial<Department> = {}): Department {
  return {
    id: 'dept-1',
    name: 'Engineering',
    headEmployeeId: 'head-1',
    isArchived: false,
    ...overrides,
  } as Department;
}

function buildLeaveType(overrides: Partial<LeaveType> = {}): LeaveType {
  return {
    id: 'leave-type-1',
    name: 'Annual Leave',
    annualAllowanceDays: '20.0',
    carryForwardLimitDays: undefined,
    colorHex: undefined,
    isArchived: false,
    ...overrides,
  } as LeaveType;
}

function buildLeaveRequest(overrides: Partial<LeaveRequest> = {}): LeaveRequest {
  return {
    id: 'request-1',
    employeeId: 'employee-1',
    employee: buildEmployee(),
    leaveTypeId: 'leave-type-1',
    leaveType: buildLeaveType(),
    startDate: '2026-03-02', // Monday
    endDate: '2026-03-06', // Friday
    numberOfDays: '5.0',
    reason: 'Trip',
    status: LeaveRequestStatus.SUBMITTED,
    createdAt: new Date('2026-01-01T00:00:00Z'),
    ...overrides,
  } as LeaveRequest;
}

function buildBalance(overrides: Partial<LeaveBalance> = {}): LeaveBalance {
  return {
    id: 'balance-1',
    employeeId: 'employee-1',
    leaveTypeId: 'leave-type-1',
    leaveType: buildLeaveType(),
    year: 2026,
    allocated: '20.0',
    used: '0.0',
    ...overrides,
  } as LeaveBalance;
}

describe('LeaveService', () => {
  let service: LeaveService;
  let leaveTypeRepository: jest.Mocked<LeaveTypeRepository>;
  let leaveBalanceRepository: jest.Mocked<LeaveBalanceRepository>;
  let leaveRequestRepository: jest.Mocked<LeaveRequestRepository>;
  let leaveBalanceAdjustmentRepository: jest.Mocked<LeaveBalanceAdjustmentRepository>;
  let employeeRepository: jest.Mocked<EmployeeRepository>;
  let userRepository: jest.Mocked<UserRepository>;
  let departmentRepository: jest.Mocked<DepartmentRepository>;
  let holidaysService: jest.Mocked<HolidaysService>;
  let notificationsService: jest.Mocked<NotificationsService>;
  let rolesService: jest.Mocked<RolesService>;

  beforeEach(() => {
    leaveTypeRepository = {
      findAll: jest.fn(),
      findById: jest.fn(),
      save: jest.fn(),
      remove: jest.fn(),
    };
    leaveBalanceRepository = {
      findOne: jest.fn(),
      findByEmployeeId: jest.fn(),
      findByYear: jest.fn(),
      save: jest.fn(),
      saveMany: jest.fn(),
    };
    leaveRequestRepository = {
      findById: jest.fn(),
      findByEmployeeId: jest.fn(),
      findByStatus: jest.fn(),
      findByStatuses: jest.fn(),
      save: jest.fn(),
    };
    leaveBalanceAdjustmentRepository = {
      findByEmployeeId: jest.fn(),
      save: jest.fn(),
    };
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
    departmentRepository = {
      findAll: jest.fn(),
      findById: jest.fn(),
      save: jest.fn(),
      remove: jest.fn(),
    };
    // Defaults to a department whose head is someone other than the default
    // employee, so pre-existing tests that don't care about the approval
    // routing keep seeing a SUBMITTED request, as before.
    departmentRepository.findById.mockResolvedValue(buildDepartment());
    departmentRepository.findAll.mockResolvedValue([buildDepartment()]);
    // Defaults to no holidays so every pre-existing test below keeps behaving
    // exactly as it did before holidays were wired in.
    holidaysService = {
      getDatesInRange: jest.fn().mockResolvedValue([]),
    } as unknown as jest.Mocked<HolidaysService>;
    notificationsService = {
      create: jest.fn(),
    } as unknown as jest.Mocked<NotificationsService>;
    rolesService = {
      findUsersWithPermission: jest.fn().mockResolvedValue([]),
    } as unknown as jest.Mocked<RolesService>;

    service = new LeaveService(
      leaveTypeRepository,
      leaveBalanceRepository,
      leaveRequestRepository,
      leaveBalanceAdjustmentRepository,
      employeeRepository,
      userRepository,
      departmentRepository,
      holidaysService,
      notificationsService,
      rolesService,
    );
  });

  describe('submitLeaveRequest', () => {
    const dto = {
      leaveTypeId: 'leave-type-1',
      startDate: '2026-03-02', // Monday
      endDate: '2026-03-06', // Friday
      reason: 'Trip',
    };

    it('throws NotFoundException when the caller has no employee profile', async () => {
      employeeRepository.findByUserId.mockResolvedValue(null);

      await expect(
        service.submitLeaveRequest('user-1', dto),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('computes working days across a weekend, excluding Sat/Sun', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      leaveTypeRepository.findById.mockResolvedValue(buildLeaveType());
      leaveBalanceRepository.findOne.mockResolvedValue(null);
      leaveRequestRepository.save.mockImplementation((r) => Promise.resolve(r));
      leaveRequestRepository.findById.mockImplementation((id) =>
        Promise.resolve(buildLeaveRequest({ id })),
      );

      // Friday 2026-03-06 through Monday 2026-03-09 = 2 working days (Fri, Mon).
      const result = await service.submitLeaveRequest('user-1', {
        ...dto,
        startDate: '2026-03-06',
        endDate: '2026-03-09',
      });

      expect(leaveRequestRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ numberOfDays: '2.0' }),
      );
      expect(result.status).toBe(LeaveRequestStatus.SUBMITTED);
    });

    it('excludes a public holiday that falls on a weekday from the working-day count', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      leaveTypeRepository.findById.mockResolvedValue(buildLeaveType());
      leaveBalanceRepository.findOne.mockResolvedValue(null);
      leaveRequestRepository.save.mockImplementation((r) => Promise.resolve(r));
      leaveRequestRepository.findById.mockImplementation((id) =>
        Promise.resolve(buildLeaveRequest({ id })),
      );
      // 2026-03-02 through 2026-03-06 (Mon-Fri) would otherwise be 5 working
      // days; mark Wednesday 2026-03-04 as a public holiday.
      holidaysService.getDatesInRange.mockResolvedValue(['2026-03-04']);

      const result = await service.submitLeaveRequest('user-1', {
        ...dto,
        startDate: '2026-03-02',
        endDate: '2026-03-06',
      });

      expect(leaveRequestRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ numberOfDays: '4.0' }),
      );
      expect(result.status).toBe(LeaveRequestStatus.SUBMITTED);
    });

    it('creates a SUBMITTED request when the employee\'s department has a head', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      departmentRepository.findById.mockResolvedValue(
        buildDepartment({ headEmployeeId: 'head-1' }),
      );
      leaveTypeRepository.findById.mockResolvedValue(buildLeaveType());
      leaveBalanceRepository.findOne.mockResolvedValue(null);
      leaveRequestRepository.save.mockImplementation((r) => Promise.resolve(r));
      leaveRequestRepository.findById.mockImplementation((id) =>
        Promise.resolve(buildLeaveRequest({ id })),
      );

      await service.submitLeaveRequest('user-1', dto);

      expect(leaveRequestRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ status: LeaveRequestStatus.SUBMITTED }),
      );
    });

    it('skips straight to MANAGER_APPROVED when the employee has no department', async () => {
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ departmentId: undefined }),
      );
      leaveTypeRepository.findById.mockResolvedValue(buildLeaveType());
      leaveBalanceRepository.findOne.mockResolvedValue(null);
      leaveRequestRepository.save.mockImplementation((r) => Promise.resolve(r));
      leaveRequestRepository.findById.mockImplementation((id) =>
        Promise.resolve(buildLeaveRequest({ id })),
      );

      await service.submitLeaveRequest('user-1', dto);

      expect(leaveRequestRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ status: LeaveRequestStatus.MANAGER_APPROVED }),
      );
    });

    it('skips straight to MANAGER_APPROVED when the department has no head assigned', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      departmentRepository.findById.mockResolvedValue(
        buildDepartment({ headEmployeeId: undefined }),
      );
      leaveTypeRepository.findById.mockResolvedValue(buildLeaveType());
      leaveBalanceRepository.findOne.mockResolvedValue(null);
      leaveRequestRepository.save.mockImplementation((r) => Promise.resolve(r));
      leaveRequestRepository.findById.mockImplementation((id) =>
        Promise.resolve(buildLeaveRequest({ id })),
      );

      await service.submitLeaveRequest('user-1', dto);

      expect(leaveRequestRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ status: LeaveRequestStatus.MANAGER_APPROVED }),
      );
    });

    it('skips straight to MANAGER_APPROVED when the employee is the head of their own department', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee({ id: 'head-1' }));
      departmentRepository.findById.mockResolvedValue(
        buildDepartment({ headEmployeeId: 'head-1' }),
      );
      leaveTypeRepository.findById.mockResolvedValue(buildLeaveType());
      leaveBalanceRepository.findOne.mockResolvedValue(null);
      leaveRequestRepository.save.mockImplementation((r) => Promise.resolve(r));
      leaveRequestRepository.findById.mockImplementation((id) =>
        Promise.resolve(buildLeaveRequest({ id })),
      );

      await service.submitLeaveRequest('user-1', dto);

      expect(leaveRequestRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ status: LeaveRequestStatus.MANAGER_APPROVED }),
      );
    });

    it('throws BadRequestException when the request exceeds the remaining balance', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      leaveTypeRepository.findById.mockResolvedValue(buildLeaveType());
      leaveBalanceRepository.findOne.mockResolvedValue(
        buildBalance({ allocated: '5.0', used: '4.0' }), // only 1 day remaining
      );

      await expect(
        service.submitLeaveRequest('user-1', dto), // 5 working days requested
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('getPendingManagerApproval', () => {
    it('returns an empty array when the actor has no employee profile', async () => {
      employeeRepository.findByUserId.mockResolvedValue(null);

      const result = await service.getPendingManagerApproval('user-1');

      expect(result).toEqual([]);
    });

    it('returns an empty array when the actor does not head any department', async () => {
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'not-a-head' }),
      );
      departmentRepository.findAll.mockResolvedValue([
        buildDepartment({ id: 'dept-1', headEmployeeId: 'head-1' }),
      ]);

      const result = await service.getPendingManagerApproval('user-1');

      expect(result).toEqual([]);
    });

    it('only returns submitted requests from departments the actor heads', async () => {
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'head-1' }),
      );
      departmentRepository.findAll.mockResolvedValue([
        buildDepartment({ id: 'dept-1', headEmployeeId: 'head-1' }),
        buildDepartment({ id: 'dept-2', headEmployeeId: 'someone-else' }),
      ]);
      leaveRequestRepository.findByStatus.mockResolvedValue([
        buildLeaveRequest({
          id: 'request-mine',
          employee: buildEmployee({ id: 'member-1', departmentId: 'dept-1' }),
        }),
        buildLeaveRequest({
          id: 'request-not-mine',
          employee: buildEmployee({ id: 'member-2', departmentId: 'dept-2' }),
        }),
      ]);

      const result = await service.getPendingManagerApproval('user-1');

      expect(result.map((r) => r.id)).toEqual(['request-mine']);
    });
  });

  describe('approveAsManager / rejectAsManager', () => {
    it('throws ForbiddenException when the actor does not head the request\'s department', async () => {
      leaveRequestRepository.findById.mockResolvedValue(
        buildLeaveRequest({
          employee: buildEmployee({ departmentId: 'dept-1' }),
        }),
      );
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'not-a-head' }),
      );
      departmentRepository.findAll.mockResolvedValue([
        buildDepartment({ id: 'dept-1', headEmployeeId: 'head-1' }),
      ]);

      await expect(
        service.approveAsManager('request-1', 'user-1'),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('throws BadRequestException once the request has moved past the department-head stage', async () => {
      leaveRequestRepository.findById.mockResolvedValue(
        buildLeaveRequest({ status: LeaveRequestStatus.MANAGER_APPROVED }),
      );

      await expect(
        service.approveAsManager('request-1', 'user-1'),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('approves as the department head and records their name', async () => {
      leaveRequestRepository.findById.mockResolvedValue(
        buildLeaveRequest({
          employee: buildEmployee({ departmentId: 'dept-1' }),
        }),
      );
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'head-1', firstName: 'Amir', lastName: 'Khan' }),
      );
      departmentRepository.findAll.mockResolvedValue([
        buildDepartment({ id: 'dept-1', headEmployeeId: 'head-1' }),
      ]);
      leaveRequestRepository.save.mockImplementation((r) => Promise.resolve(r));

      const result = await service.approveAsManager('request-1', 'user-1', 'Go ahead');

      expect(result.status).toBe(LeaveRequestStatus.MANAGER_APPROVED);
      expect(result.managerDecisionByName).toBe('Amir Khan');
      expect(result.managerComment).toBe('Go ahead');
    });

    it('rejects as the department head', async () => {
      leaveRequestRepository.findById.mockResolvedValue(
        buildLeaveRequest({
          employee: buildEmployee({ departmentId: 'dept-1' }),
        }),
      );
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'head-1' }),
      );
      departmentRepository.findAll.mockResolvedValue([
        buildDepartment({ id: 'dept-1', headEmployeeId: 'head-1' }),
      ]);
      leaveRequestRepository.save.mockImplementation((r) => Promise.resolve(r));

      const result = await service.rejectAsManager('request-1', 'user-1', 'Not now');

      expect(result.status).toBe(LeaveRequestStatus.REJECTED);
      expect(result.managerComment).toBe('Not now');
    });
  });

  describe('cancelLeaveRequest', () => {
    it('throws NotFoundException when the request belongs to someone else', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      leaveRequestRepository.findById.mockResolvedValue(
        buildLeaveRequest({ employeeId: 'someone-else' }),
      );

      await expect(
        service.cancelLeaveRequest('user-1', 'request-1'),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('throws BadRequestException once the request is already approved', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      leaveRequestRepository.findById.mockResolvedValue(
        buildLeaveRequest({ status: LeaveRequestStatus.APPROVED }),
      );

      await expect(
        service.cancelLeaveRequest('user-1', 'request-1'),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('cancels a request pending manager approval', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      leaveRequestRepository.findById.mockResolvedValue(
        buildLeaveRequest({ status: LeaveRequestStatus.MANAGER_APPROVED }),
      );
      leaveRequestRepository.save.mockImplementation((r) => Promise.resolve(r));

      const result = await service.cancelLeaveRequest('user-1', 'request-1');

      expect(result.status).toBe(LeaveRequestStatus.CANCELLED);
    });
  });

  describe('approveAsHr', () => {
    it('throws BadRequestException when not yet manager-approved', async () => {
      leaveRequestRepository.findById.mockResolvedValue(
        buildLeaveRequest({ status: LeaveRequestStatus.SUBMITTED }),
      );

      await expect(
        service.approveAsHr('request-1', 'hr-1'),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('throws BadRequestException when the balance has since become insufficient', async () => {
      leaveRequestRepository.findById.mockResolvedValue(
        buildLeaveRequest({
          status: LeaveRequestStatus.MANAGER_APPROVED,
          numberOfDays: '5.0',
        }),
      );
      leaveBalanceRepository.findOne.mockResolvedValue(
        buildBalance({ allocated: '5.0', used: '4.0' }),
      );

      await expect(
        service.approveAsHr('request-1', 'hr-1'),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('increments the balance used and marks the request APPROVED', async () => {
      leaveRequestRepository.findById.mockResolvedValue(
        buildLeaveRequest({
          status: LeaveRequestStatus.MANAGER_APPROVED,
          numberOfDays: '5.0',
        }),
      );
      leaveBalanceRepository.findOne.mockResolvedValue(
        buildBalance({ allocated: '20.0', used: '0.0' }),
      );
      leaveBalanceRepository.save.mockImplementation((b) => Promise.resolve(b));
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ firstName: 'Zahra', lastName: 'Shiraz' }),
      );
      leaveRequestRepository.save.mockImplementation((r) => Promise.resolve(r));

      const result = await service.approveAsHr('request-1', 'hr-1', 'Enjoy!');

      expect(leaveBalanceRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ used: '5.0' }),
      );
      expect(result.status).toBe(LeaveRequestStatus.APPROVED);
      expect(result.hrDecisionByName).toBe('Zahra Shiraz');
      expect(result.hrComment).toBe('Enjoy!');
    });
  });

  describe('getLeaveCalendar', () => {
    it('only includes members of departments the viewer heads, for team scope', async () => {
      const teamRequest = buildLeaveRequest({
        id: 'request-team',
        employeeId: 'member-1',
        employee: buildEmployee({ id: 'member-1', departmentId: 'dept-1' }),
        status: LeaveRequestStatus.APPROVED,
      });
      const otherRequest = buildLeaveRequest({
        id: 'request-other',
        employeeId: 'someone-else',
        employee: buildEmployee({ id: 'someone-else', departmentId: 'dept-2' }),
        status: LeaveRequestStatus.APPROVED,
      });
      leaveRequestRepository.findByStatuses.mockResolvedValue([
        teamRequest,
        otherRequest,
      ]);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'head-1' }),
      );
      departmentRepository.findAll.mockResolvedValue([
        buildDepartment({ id: 'dept-1', headEmployeeId: 'head-1' }),
        buildDepartment({ id: 'dept-2', headEmployeeId: 'someone-elses-head' }),
      ]);

      const result = await service.getLeaveCalendar(
        'user-1',
        'team',
        3,
        2026,
        false,
      );

      expect(result.map((r) => r.employeeId)).toEqual(['member-1']);
    });

    it('returns nothing for team scope when the viewer does not head any department', async () => {
      leaveRequestRepository.findByStatuses.mockResolvedValue([
        buildLeaveRequest({ employeeId: 'member-1', employee: buildEmployee({ id: 'member-1' }) }),
      ]);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'not-a-head' }),
      );
      departmentRepository.findAll.mockResolvedValue([
        buildDepartment({ id: 'dept-1', headEmployeeId: 'head-1' }),
      ]);

      const result = await service.getLeaveCalendar(
        'user-1',
        'team',
        3,
        2026,
        false,
      );

      expect(result).toHaveLength(0);
    });

    it('includes everyone for company scope', async () => {
      leaveRequestRepository.findByStatuses.mockResolvedValue([
        buildLeaveRequest({ employeeId: 'employee-a', employee: buildEmployee({ id: 'employee-a' }) }),
        buildLeaveRequest({ employeeId: 'employee-b', employee: buildEmployee({ id: 'employee-b' }) }),
      ]);

      const result = await service.getLeaveCalendar(
        'user-1',
        'company',
        3,
        2026,
        false,
      );

      expect(result).toHaveLength(2);
    });

    it('excludes requests outside the queried month', async () => {
      leaveRequestRepository.findByStatuses.mockResolvedValue([
        buildLeaveRequest({ startDate: '2026-04-01', endDate: '2026-04-05' }),
      ]);

      const result = await service.getLeaveCalendar(
        'user-1',
        'company',
        3,
        2026,
        false,
      );

      expect(result).toHaveLength(0);
    });

    it("genericizes the leave type on company scope for a viewer without leave.manage — regression: the company-wide calendar previously revealed every coworker's specific leave type (e.g. 'Sick Leave'), which is health-adjacent personal information, to any authenticated user", async () => {
      leaveRequestRepository.findByStatuses.mockResolvedValue([
        buildLeaveRequest({
          employee: buildEmployee({ id: 'employee-a' }),
          leaveType: buildLeaveType({ id: 'type-1', name: 'Sick Leave', colorHex: '#ff0000' }),
        }),
      ]);

      const result = await service.getLeaveCalendar(
        'user-1',
        'company',
        3,
        2026,
        false,
      );

      expect(result[0].leaveTypeName).toBe('On Leave');
      expect(result[0].colorHex).toBeNull();
    });

    it('shows the real leave type on company scope to a leave.manage holder', async () => {
      leaveRequestRepository.findByStatuses.mockResolvedValue([
        buildLeaveRequest({
          employee: buildEmployee({ id: 'employee-a' }),
          leaveType: buildLeaveType({ id: 'type-1', name: 'Sick Leave', colorHex: '#ff0000' }),
        }),
      ]);

      const result = await service.getLeaveCalendar(
        'user-1',
        'company',
        3,
        2026,
        true,
      );

      expect(result[0].leaveTypeName).toBe('Sick Leave');
      expect(result[0].colorHex).toBe('#ff0000');
    });

    it('shows the real leave type on team scope even without leave.manage, since that scope is already restricted to the department head', async () => {
      leaveRequestRepository.findByStatuses.mockResolvedValue([
        buildLeaveRequest({
          employeeId: 'member-1',
          employee: buildEmployee({ id: 'member-1', departmentId: 'dept-1' }),
          leaveType: buildLeaveType({ id: 'type-1', name: 'Sick Leave', colorHex: '#ff0000' }),
        }),
      ]);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'head-1' }),
      );
      departmentRepository.findAll.mockResolvedValue([
        buildDepartment({ id: 'dept-1', headEmployeeId: 'head-1' }),
      ]);

      const result = await service.getLeaveCalendar(
        'user-1',
        'team',
        3,
        2026,
        false,
      );

      expect(result[0].leaveTypeName).toBe('Sick Leave');
    });
  });

  describe('getMyBalances', () => {
    it('returns a virtual balance at full allowance when no row exists yet', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
      leaveTypeRepository.findAll.mockResolvedValue([buildLeaveType()]);
      leaveBalanceRepository.findByEmployeeId.mockResolvedValue([]);

      const result = await service.getMyBalances('user-1');

      expect(result).toEqual([
        expect.objectContaining({ allocated: 20, used: 0, remaining: 20 }),
      ]);
      expect(leaveBalanceRepository.save).not.toHaveBeenCalled();
    });
  });

  describe('runAnnualReset', () => {
    it('creates balances only for combinations that do not already exist this year', async () => {
      const employeeA = buildEmployee({ id: 'employee-a' });
      const employeeB = buildEmployee({ id: 'employee-b' });
      employeeRepository.findAll.mockResolvedValue([employeeA, employeeB]);
      leaveTypeRepository.findAll.mockResolvedValue([buildLeaveType({ id: 'type-1' })]);
      leaveBalanceRepository.findByYear.mockResolvedValue([
        buildBalance({ employeeId: 'employee-a', leaveTypeId: 'type-1' }),
      ]);
      leaveBalanceRepository.saveMany.mockImplementation((b) => Promise.resolve(b));

      const result = await service.runAnnualReset();

      expect(leaveBalanceRepository.saveMany).toHaveBeenCalledWith([
        expect.objectContaining({ employeeId: 'employee-b', leaveTypeId: 'type-1' }),
      ]);
      expect(result.balancesCreated).toBe(1);
    });

    it('is a no-op when every combination already has a balance this year', async () => {
      const employeeA = buildEmployee({ id: 'employee-a' });
      employeeRepository.findAll.mockResolvedValue([employeeA]);
      leaveTypeRepository.findAll.mockResolvedValue([buildLeaveType({ id: 'type-1' })]);
      leaveBalanceRepository.findByYear.mockResolvedValue([
        buildBalance({ employeeId: 'employee-a', leaveTypeId: 'type-1' }),
      ]);

      const result = await service.runAnnualReset();

      expect(leaveBalanceRepository.saveMany).not.toHaveBeenCalled();
      expect(result.balancesCreated).toBe(0);
    });
  });

  describe('handleDailyAnnualResetCheck', () => {
    it('does nothing when the year is already initialized', async () => {
      leaveBalanceRepository.findByYear.mockResolvedValue([buildBalance()]);

      await service.handleDailyAnnualResetCheck();

      expect(notificationsService.create).not.toHaveBeenCalled();
    });

    it('notifies every active employee directly and every leave.manage holder once the reset runs, skipping non-active employees', async () => {
      const employeeA = buildEmployee({
        id: 'employee-a',
        userId: 'user-a',
        employmentStatus: EmploymentStatus.ACTIVE,
      });
      const employeeB = buildEmployee({
        id: 'employee-b',
        userId: 'user-b',
        employmentStatus: EmploymentStatus.RESIGNED,
      });
      leaveBalanceRepository.findByYear
        .mockResolvedValueOnce([]) // getResetStatus: not yet initialized
        .mockResolvedValueOnce([]); // inside runAnnualReset: no existing balances
      employeeRepository.findAll.mockResolvedValue([employeeA, employeeB]);
      leaveTypeRepository.findAll.mockResolvedValue([buildLeaveType({ id: 'type-1' })]);
      leaveBalanceRepository.saveMany.mockImplementation((b) => Promise.resolve(b));
      rolesService.findUsersWithPermission.mockResolvedValue([{ id: 'admin-1' } as never]);

      await service.handleDailyAnnualResetCheck();

      expect(notificationsService.create).toHaveBeenCalledWith(
        expect.objectContaining({ recipientUserId: 'user-a' }),
      );
      expect(notificationsService.create).not.toHaveBeenCalledWith(
        expect.objectContaining({ recipientUserId: 'user-b' }),
      );
      expect(notificationsService.create).toHaveBeenCalledWith(
        expect.objectContaining({ recipientUserId: 'admin-1' }),
      );
    });
  });
});
