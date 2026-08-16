import { BadRequestException, NotFoundException } from '@nestjs/common';
import type { UserRepository } from '../../authentication/domain/repositories/user-repository.interface';
import { Employee } from '../../employee/domain/entities/employee.entity';
import { EmploymentStatus } from '../../employee/domain/enums/employment-status.enum';
import type { EmployeeRepository } from '../../employee/domain/repositories/employee-repository.interface';
import type { HolidaysService } from '../../holidays/application/holidays.service';
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
    reportingManagerId: 'manager-1',
    employmentStatus: EmploymentStatus.ACTIVE,
    profilePhotoUrl: undefined,
    ...overrides,
  } as Employee;
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
  let holidaysService: jest.Mocked<HolidaysService>;

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
    // Defaults to no holidays so every pre-existing test below keeps behaving
    // exactly as it did before holidays were wired in.
    holidaysService = {
      getDatesInRange: jest.fn().mockResolvedValue([]),
    } as unknown as jest.Mocked<HolidaysService>;

    service = new LeaveService(
      leaveTypeRepository,
      leaveBalanceRepository,
      leaveRequestRepository,
      leaveBalanceAdjustmentRepository,
      employeeRepository,
      userRepository,
      holidaysService,
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

    it('creates a SUBMITTED request when the employee has a reporting manager', async () => {
      employeeRepository.findByUserId.mockResolvedValue(buildEmployee());
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

    it('skips straight to MANAGER_APPROVED when the employee has no reporting manager', async () => {
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ reportingManagerId: undefined }),
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
    it('only includes the viewer and their direct reports for team scope', async () => {
      const teamRequest = buildLeaveRequest({
        id: 'request-team',
        employeeId: 'report-1',
        employee: buildEmployee({ id: 'report-1' }),
        status: LeaveRequestStatus.APPROVED,
      });
      const otherRequest = buildLeaveRequest({
        id: 'request-other',
        employeeId: 'someone-else',
        employee: buildEmployee({ id: 'someone-else' }),
        status: LeaveRequestStatus.APPROVED,
      });
      leaveRequestRepository.findByStatuses.mockResolvedValue([
        teamRequest,
        otherRequest,
      ]);
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'manager-1' }),
      );
      employeeRepository.findByReportingManagerId.mockResolvedValue([
        buildEmployee({ id: 'report-1' }),
      ]);

      const result = await service.getLeaveCalendar(
        'user-1',
        'team',
        3,
        2026,
      );

      expect(result.map((r) => r.employeeId)).toEqual(['report-1']);
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
      );

      expect(result).toHaveLength(0);
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
});
