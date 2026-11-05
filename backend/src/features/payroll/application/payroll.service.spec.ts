import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import type { UserRepository } from '../../authentication/domain/repositories/user-repository.interface';
import { Employee } from '../../employee/domain/entities/employee.entity';
import { EmployeesService } from '../../employee/application/employees.service';
import { EmploymentStatus } from '../../employee/domain/enums/employment-status.enum';
import type { EmployeeRepository } from '../../employee/domain/repositories/employee-repository.interface';
import { Freelancer } from '../../freelancers/domain/entities/freelancer.entity';
import type { FreelancerRepository } from '../../freelancers/domain/repositories/freelancer-repository.interface';
import { PayrollLineItem } from '../domain/entities/payroll-line-item.entity';
import { PayrollRun } from '../domain/entities/payroll-run.entity';
import { PayrollRunStatus } from '../domain/enums/payroll-run-status.enum';
import type { PayrollLineItemRepository } from '../domain/repositories/payroll-line-item-repository.interface';
import type { PayrollRunRepository } from '../domain/repositories/payroll-run-repository.interface';
import type { AttendanceService } from '../../attendance/application/attendance.service';
import type { RolesService } from '../../authentication/application/roles.service';
import type { NotificationsService } from '../../notifications/application/notifications.service';
import { PayrollService } from './payroll.service';

function buildEmployee(overrides: Partial<Employee> = {}): Employee {
  return {
    id: 'employee-1',
    userId: 'user-employee-1',
    firstName: 'Jane',
    lastName: 'Doe',
    profilePhotoUrl: undefined,
    employmentStatus: EmploymentStatus.ACTIVE,
    ...overrides,
  } as Employee;
}

function buildRun(overrides: Partial<PayrollRun> = {}): PayrollRun {
  return {
    id: 'run-1',
    month: 8,
    year: 2026,
    status: PayrollRunStatus.DRAFT,
    generatedByName: 'Noushad Ranani',
    finalizedByName: null,
    finalizedAt: null,
    paidByName: null,
    paidAt: null,
    createdAt: new Date('2026-08-01T00:00:00.000Z'),
    updatedAt: new Date('2026-08-01T00:00:00.000Z'),
    ...overrides,
  } as PayrollRun;
}

function buildFreelancer(overrides: Partial<Freelancer> = {}): Freelancer {
  return {
    id: 'freelancer-1',
    fullName: 'Kulsum Zehra',
    role: 'Content Writer',
    notes: null,
    isActive: true,
    ...overrides,
  } as Freelancer;
}

function buildLineItem(
  overrides: Partial<PayrollLineItem> = {},
): PayrollLineItem {
  return {
    id: 'item-1',
    runId: 'run-1',
    employeeId: 'employee-1',
    employee: buildEmployee(),
    freelancerId: null,
    freelancer: null,
    baseSalary: '50000.00',
    lateDays: 0,
    lateDeductionDays: 0,
    lateHours: '0.00',
    absentDays: 0,
    advanceSalary: '0.00',
    fines: [],
    freelanceTasks: [],
    notes: null,
    createdAt: new Date('2026-08-01T00:00:00.000Z'),
    updatedAt: new Date('2026-08-01T00:00:00.000Z'),
    ...overrides,
  } as PayrollLineItem;
}

describe('PayrollService', () => {
  let service: PayrollService;
  let runRepository: jest.Mocked<PayrollRunRepository>;
  let lineItemRepository: jest.Mocked<PayrollLineItemRepository>;
  let employeeRepository: jest.Mocked<EmployeeRepository>;
  let userRepository: jest.Mocked<UserRepository>;
  let freelancerRepository: jest.Mocked<FreelancerRepository>;
  let employeesService: jest.Mocked<EmployeesService>;
  let notificationsService: jest.Mocked<NotificationsService>;
  let attendanceService: jest.Mocked<AttendanceService>;
  let rolesService: jest.Mocked<RolesService>;

  beforeEach(() => {
    runRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      findByMonthYear: jest.fn().mockResolvedValue(null),
      save: jest.fn((run) =>
        Promise.resolve({
          ...run,
          id: run.id ?? 'run-1',
          createdAt: run.createdAt ?? new Date('2026-08-01T00:00:00.000Z'),
          updatedAt: new Date('2026-08-01T00:00:00.000Z'),
        } as PayrollRun),
      ),
    };
    lineItemRepository = {
      findByRunId: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      save: jest.fn((item) => Promise.resolve(item)),
      saveMany: jest.fn((items) =>
        Promise.resolve(
          items.map(
            (item, i) =>
              ({
                ...item,
                id: item.id ?? `item-${i + 1}`,
                createdAt: new Date('2026-08-01T00:00:00.000Z'),
                updatedAt: new Date('2026-08-01T00:00:00.000Z'),
              }) as PayrollLineItem,
          ),
        ),
      ),
    };
    employeeRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      findByUserId: jest.fn().mockResolvedValue(null),
      findByReportingManagerId: jest.fn(),
      count: jest.fn(),
      save: jest.fn(),
    };
    userRepository = {
      findByEmail: jest.fn(),
      findById: jest
        .fn()
        .mockResolvedValue({ id: 'admin-1', email: 'admin@zeracreative.com' }),
      findAll: jest.fn(),
      save: jest.fn(),
    };
    freelancerRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      save: jest.fn((freelancer) => Promise.resolve(freelancer)),
    };
    employeesService = {
      getSalaryAsOf: jest.fn().mockResolvedValue(0),
    } as unknown as jest.Mocked<EmployeesService>;
    notificationsService = {
      create: jest.fn(),
    } as unknown as jest.Mocked<NotificationsService>;

    attendanceService = {
      refreshIfStale: jest.fn().mockResolvedValue({}),
      getCompanyMonth: jest.fn().mockResolvedValue([]),
    } as unknown as jest.Mocked<AttendanceService>;
    rolesService = {
      findUsersWithPermission: jest.fn().mockResolvedValue([]),
    } as unknown as jest.Mocked<RolesService>;

    service = new PayrollService(
      runRepository,
      lineItemRepository,
      employeeRepository,
      userRepository,
      freelancerRepository,
      employeesService,
      notificationsService,
      attendanceService,
      rolesService,
    );
  });

  describe('generateRun', () => {
    it("creates a run and one line item per active employee, with baseSalary and netPay defaulted from that month's salary", async () => {
      employeeRepository.findAll.mockResolvedValue([
        buildEmployee({ id: 'e1', employmentStatus: EmploymentStatus.ACTIVE }),
        buildEmployee({
          id: 'e2',
          employmentStatus: EmploymentStatus.RESIGNED,
        }),
      ]);
      employeesService.getSalaryAsOf.mockResolvedValue(75000);
      lineItemRepository.findByRunId.mockResolvedValue([
        buildLineItem({ employeeId: 'e1', baseSalary: '75000.00' }),
      ]);

      const result = await service.generateRun(
        { month: 8, year: 2026 },
        'admin-1',
      );

      expect(employeesService.getSalaryAsOf).toHaveBeenCalledWith(
        'e1',
        '2026-08-31',
      );
      expect(employeesService.getSalaryAsOf).toHaveBeenCalledTimes(1); // e2 excluded
      expect(result.lineItems).toHaveLength(1);
      expect(result.lineItems[0].baseSalary).toBe(75000);
      expect(result.lineItems[0].netPay).toBe(75000);
      expect(result.status).toBe(PayrollRunStatus.DRAFT);
    });

    it("fills each employee's late days from that month's attendance", async () => {
      employeeRepository.findAll.mockResolvedValue([
        buildEmployee({ id: 'e1' }),
        buildEmployee({ id: 'e2' }),
      ]);
      employeesService.getSalaryAsOf.mockResolvedValue(60000);
      attendanceService.getCompanyMonth.mockResolvedValue([
        {
          employeeId: 'e1',
          linked: true,
          summary: { late: 7, lateDeductionDays: 2 },
        },
        {
          employeeId: 'e2',
          linked: false,
          summary: { late: 9, lateDeductionDays: 3 },
        },
      ] as never);

      await service.generateRun({ month: 8, year: 2026 }, 'admin-1');

      expect(attendanceService.getCompanyMonth).toHaveBeenCalledWith(8, 2026);
      const saved = lineItemRepository.saveMany.mock.calls[0][0];
      expect(saved[0]).toMatchObject({ lateDays: 7, lateDeductionDays: 2 });
      // Not linked to the machine: nothing to count.
      expect(saved[1]).toMatchObject({ lateDays: 0, lateDeductionDays: 0 });
    });

    it('leaves out an active employee who has no salary on file', async () => {
      employeeRepository.findAll.mockResolvedValue([
        buildEmployee({ id: 'paid' }),
        buildEmployee({ id: 'owner' }),
      ]);
      employeesService.getSalaryAsOf.mockImplementation((id) =>
        Promise.resolve(id === 'owner' ? 0 : 50000),
      );

      await service.generateRun({ month: 8, year: 2026 }, 'admin-1');

      const saved = lineItemRepository.saveMany.mock.calls[0][0];
      expect(saved.map((i) => i.employeeId)).toEqual(['paid']);
    });

    it('throws ConflictException when a run already exists for that month/year', async () => {
      runRepository.findByMonthYear.mockResolvedValue(buildRun());

      await expect(
        service.generateRun({ month: 8, year: 2026 }, 'admin-1'),
      ).rejects.toBeInstanceOf(ConflictException);
    });
  });

  describe('updateLineItem', () => {
    it('edits fines and freelance tasks, and netPay reflects both', async () => {
      runRepository.findById.mockResolvedValue(
        buildRun({ status: PayrollRunStatus.DRAFT }),
      );
      lineItemRepository.findById.mockResolvedValue(buildLineItem());
      lineItemRepository.findByRunId.mockResolvedValue([
        buildLineItem({
          baseSalary: '50000.00',
          fines: [{ description: 'Late file', amount: 2000 }],
          freelanceTasks: [{ description: 'Logo', amount: 5000 }],
        }),
      ]);

      const result = await service.updateLineItem('run-1', 'item-1', {
        fines: [{ description: ' Late file ', amount: 2000 }],
        freelanceTasks: [{ description: ' Logo ', amount: 5000 }],
      });

      expect(lineItemRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          fines: [{ description: 'Late file', amount: 2000 }],
          freelanceTasks: [{ description: 'Logo', amount: 5000 }],
        }),
      );
      expect(result.lineItems[0].finesTotal).toBe(2000);
      expect(result.lineItems[0].freelanceTotal).toBe(5000);
      expect(result.lineItems[0].netPay).toBe(53000);
    });

    it('takes absent days at base / 30 and the advance off net pay', async () => {
      runRepository.findById.mockResolvedValue(buildRun());
      lineItemRepository.findById.mockResolvedValue(buildLineItem());
      lineItemRepository.findByRunId.mockResolvedValue([
        buildLineItem({
          baseSalary: '96000.00',
          absentDays: 10,
          advanceSalary: '5000.00',
        }),
      ]);

      const result = await service.updateLineItem('run-1', 'item-1', {
        absentDays: 10,
        advanceSalary: 5000,
      });

      expect(lineItemRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ absentDays: 10, advanceSalary: '5000.00' }),
      );
      expect(result.lineItems[0].absentDeduction).toBe(32000); // 10 x 96000/30
      expect(result.lineItems[0].netPay).toBe(59000); // 96000 - 32000 - 5000
    });

    it('rejects absent days on a freelancer line item', async () => {
      runRepository.findById.mockResolvedValue(buildRun());
      lineItemRepository.findById.mockResolvedValue(
        buildLineItem({
          employeeId: null,
          employee: null,
          freelancerId: 'freelancer-1',
          freelancer: buildFreelancer(),
        }),
      );

      await expect(
        service.updateLineItem('run-1', 'item-1', { absentDays: 2 }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('prices late hours at base / 30 / 8 per hour', async () => {
      runRepository.findById.mockResolvedValue(buildRun());
      lineItemRepository.findById.mockResolvedValue(buildLineItem());
      lineItemRepository.findByRunId.mockResolvedValue([
        buildLineItem({ baseSalary: '60000.00', lateHours: '2.00' }),
      ]);

      const result = await service.updateLineItem('run-1', 'item-1', {});

      expect(result.lineItems[0].lateHours).toBe(2);
      expect(result.lineItems[0].lateHoursDeduction).toBe(500); // 2 x 60000/30/8
      expect(result.lineItems[0].netPay).toBe(59500);
    });

    it('takes the late deduction at base salary / 30, whatever the month length', async () => {
      runRepository.findById.mockResolvedValue(buildRun());
      lineItemRepository.findById.mockResolvedValue(buildLineItem());
      lineItemRepository.findByRunId.mockResolvedValue([
        buildLineItem({
          baseSalary: '60000.00',
          lateDays: 7,
          lateDeductionDays: 2,
        }),
      ]);

      const result = await service.updateLineItem('run-1', 'item-1', {});

      expect(result.lineItems[0].lateDeduction).toBe(4000); // 2 x 60000/30
      expect(result.lineItems[0].netPay).toBe(56000);
    });

    it("allows editing a freelancer's baseSalary directly", async () => {
      runRepository.findById.mockResolvedValue(
        buildRun({ status: PayrollRunStatus.DRAFT }),
      );
      lineItemRepository.findById.mockResolvedValue(
        buildLineItem({
          employeeId: null,
          employee: null,
          freelancerId: 'freelancer-1',
          freelancer: buildFreelancer(),
        }),
      );
      lineItemRepository.findByRunId.mockResolvedValue([
        buildLineItem({
          employeeId: null,
          employee: null,
          freelancerId: 'freelancer-1',
          freelancer: buildFreelancer(),
          baseSalary: '27300.00',
        }),
      ]);

      const result = await service.updateLineItem('run-1', 'item-1', {
        baseSalary: 27300,
      });

      expect(result.lineItems[0].isFreelancer).toBe(true);
      expect(result.lineItems[0].baseSalary).toBe(27300);
    });

    it("rejects editing an employee's baseSalary directly", async () => {
      runRepository.findById.mockResolvedValue(
        buildRun({ status: PayrollRunStatus.DRAFT }),
      );
      lineItemRepository.findById.mockResolvedValue(buildLineItem());

      await expect(
        service.updateLineItem('run-1', 'item-1', { baseSalary: 99999 }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects editing a line item once the run is no longer draft', async () => {
      runRepository.findById.mockResolvedValue(
        buildRun({ status: PayrollRunStatus.FINALIZED }),
      );

      await expect(
        service.updateLineItem('run-1', 'item-1', { fines: [{ description: 'x', amount: 100 }] }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('throws NotFoundException for a line item belonging to a different run', async () => {
      runRepository.findById.mockResolvedValue(buildRun());
      lineItemRepository.findById.mockResolvedValue(
        buildLineItem({ runId: 'some-other-run' }),
      );

      await expect(
        service.updateLineItem('run-1', 'item-1', { fines: [{ description: 'x', amount: 100 }] }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  describe('syncRun', () => {
    it('refreshes late figures from attendance and keeps fines and tasks', async () => {
      runRepository.findById.mockResolvedValue(buildRun());
      const item = buildLineItem({
        fines: [{ description: 'Fine', amount: 500 }],
        freelanceTasks: [{ description: 'Logo', amount: 100 }],
      });
      lineItemRepository.findByRunId.mockResolvedValue([item]);
      attendanceService.getCompanyMonth.mockResolvedValue([
        {
          employeeId: 'employee-1',
          linked: true,
          summary: { late: 4, lateDeductionDays: 1, hoursCutMinutes: 120 },
        },
      ] as never);

      await service.syncRun('run-1');

      expect(attendanceService.getCompanyMonth).toHaveBeenCalledWith(8, 2026);
      expect(item).toMatchObject({
        lateDays: 4,
        lateDeductionDays: 1,
        lateHours: '2.00',
        fines: [{ description: 'Fine', amount: 500 }],
      });
      expect(lineItemRepository.saveMany).toHaveBeenCalled();
    });

    it('refuses once the run is no longer a draft', async () => {
      runRepository.findById.mockResolvedValue(
        buildRun({ status: PayrollRunStatus.FINALIZED }),
      );

      await expect(service.syncRun('run-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });
  });

  describe('handleMonthlyPayrollReminder', () => {
    it('reminds every payroll manager when last month has no run yet', async () => {
      rolesService.findUsersWithPermission.mockResolvedValue([
        { id: 'hr-1' },
        { id: 'admin-1' },
      ]);

      await service.handleMonthlyPayrollReminder();

      expect(rolesService.findUsersWithPermission).toHaveBeenCalledWith(
        'payroll.manage',
      );
      expect(notificationsService.create).toHaveBeenCalledTimes(2);
      expect(notificationsService.create).toHaveBeenCalledWith(
        expect.objectContaining({
          recipientUserId: 'hr-1',
          message: expect.stringContaining('generate the payroll'),
        }),
      );
    });

    it('stays quiet when the run already exists', async () => {
      runRepository.findByMonthYear.mockResolvedValue(buildRun());

      await service.handleMonthlyPayrollReminder();

      expect(notificationsService.create).not.toHaveBeenCalled();
    });
  });

  describe('addFreelancerToRun', () => {
    it('adds a freelancer line item with the entered amount as baseSalary, no fines or tasks, employeeId null', async () => {
      runRepository.findById.mockResolvedValue(
        buildRun({ status: PayrollRunStatus.DRAFT }),
      );
      freelancerRepository.findById.mockResolvedValue(buildFreelancer());
      // First call is the pre-add duplicate check (no existing items yet);
      // second is the post-save refetch used to build the response.
      lineItemRepository.findByRunId
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([
          buildLineItem({
            employeeId: null,
            employee: null,
            freelancerId: 'freelancer-1',
            freelancer: buildFreelancer(),
            baseSalary: '27300.00',
          }),
        ]);

      const result = await service.addFreelancerToRun('run-1', {
        freelancerId: 'freelancer-1',
        baseSalary: 27300,
      });

      expect(lineItemRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          runId: 'run-1',
          employeeId: null,
          freelancerId: 'freelancer-1',
          baseSalary: '27300.00',
          fines: [],
          freelanceTasks: [],
        }),
      );
      expect(result.lineItems[0].isFreelancer).toBe(true);
      expect(result.lineItems[0].employeeName).toBe('Kulsum Zehra');
      expect(result.lineItems[0].netPay).toBe(27300);
    });

    it('throws NotFoundException for an unknown freelancerId', async () => {
      runRepository.findById.mockResolvedValue(
        buildRun({ status: PayrollRunStatus.DRAFT }),
      );
      freelancerRepository.findById.mockResolvedValue(null);

      await expect(
        service.addFreelancerToRun('run-1', {
          freelancerId: 'nonexistent',
          baseSalary: 1000,
        }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('throws ConflictException when the freelancer is already in this run', async () => {
      runRepository.findById.mockResolvedValue(
        buildRun({ status: PayrollRunStatus.DRAFT }),
      );
      freelancerRepository.findById.mockResolvedValue(buildFreelancer());
      lineItemRepository.findByRunId.mockResolvedValue([
        buildLineItem({
          employeeId: null,
          employee: null,
          freelancerId: 'freelancer-1',
        }),
      ]);

      await expect(
        service.addFreelancerToRun('run-1', {
          freelancerId: 'freelancer-1',
          baseSalary: 1000,
        }),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('rejects adding a freelancer once the run is no longer draft', async () => {
      runRepository.findById.mockResolvedValue(
        buildRun({ status: PayrollRunStatus.FINALIZED }),
      );

      await expect(
        service.addFreelancerToRun('run-1', {
          freelancerId: 'freelancer-1',
          baseSalary: 1000,
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('finalizeRun', () => {
    it('moves a draft run to finalized and stamps the actor', async () => {
      runRepository.findById.mockResolvedValue(
        buildRun({ status: PayrollRunStatus.DRAFT }),
      );
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ firstName: 'Jane', lastName: 'Admin' }),
      );

      const result = await service.finalizeRun('run-1', 'admin-1');

      expect(result.status).toBe(PayrollRunStatus.FINALIZED);
      expect(result.finalizedByName).toBe('Jane Admin');
    });

    it('rejects finalizing a run that is not in draft', async () => {
      runRepository.findById.mockResolvedValue(
        buildRun({ status: PayrollRunStatus.PAID }),
      );

      await expect(
        service.finalizeRun('run-1', 'admin-1'),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('payRun', () => {
    it('moves a finalized run to paid and stamps the actor', async () => {
      runRepository.findById.mockResolvedValue(
        buildRun({ status: PayrollRunStatus.FINALIZED }),
      );

      const result = await service.payRun('run-1', 'admin-1');

      expect(result.status).toBe(PayrollRunStatus.PAID);
    });

    it('rejects marking a draft run as paid', async () => {
      runRepository.findById.mockResolvedValue(
        buildRun({ status: PayrollRunStatus.DRAFT }),
      );

      await expect(service.payRun('run-1', 'admin-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('notifies every employee with a line item in the run, unconditionally', async () => {
      runRepository.findById.mockResolvedValue(
        buildRun({ status: PayrollRunStatus.FINALIZED, month: 8, year: 2026 }),
      );
      lineItemRepository.findByRunId.mockResolvedValue([
        buildLineItem({ employee: buildEmployee({ userId: 'user-a' }) }),
        buildLineItem({
          id: 'item-2',
          employee: buildEmployee({ userId: 'user-b' }),
        }),
      ]);

      await service.payRun('run-1', 'admin-1');

      expect(notificationsService.create).toHaveBeenCalledWith(
        expect.objectContaining({
          recipientUserId: 'user-a',
          message: expect.stringContaining('August 2026'),
        }),
      );
      expect(notificationsService.create).toHaveBeenCalledWith(
        expect.objectContaining({ recipientUserId: 'user-b' }),
      );
    });

    it('skips notifying a freelancer line item (no User account to notify)', async () => {
      runRepository.findById.mockResolvedValue(
        buildRun({ status: PayrollRunStatus.FINALIZED }),
      );
      lineItemRepository.findByRunId.mockResolvedValue([
        buildLineItem({
          employeeId: null,
          employee: null,
          freelancerId: 'freelancer-1',
          freelancer: buildFreelancer(),
        }),
      ]);

      await service.payRun('run-1', 'admin-1');

      expect(notificationsService.create).not.toHaveBeenCalled();
    });
  });

  describe('getRuns', () => {
    it('returns a summary with totalNetPay across all line items', async () => {
      runRepository.findAll.mockResolvedValue([buildRun()]);
      lineItemRepository.findByRunId.mockResolvedValue([
        buildLineItem({
          baseSalary: '50000.00',
          freelanceTasks: [{ description: 'Task', amount: 2000 }],
        }),
        buildLineItem({ id: 'item-2', baseSalary: '60000.00' }),
      ]);

      const result = await service.getRuns();

      expect(result[0].employeeCount).toBe(2);
      expect(result[0].totalNetPay).toBe(112000); // 52000 + 60000
    });
  });

  describe('getRun', () => {
    it("breaks the run's netPay down by department, freelancers and unassigned employees each in their own bucket", async () => {
      runRepository.findById.mockResolvedValue(buildRun());
      lineItemRepository.findByRunId.mockResolvedValue([
        buildLineItem({
          id: 'item-eng-1',
          employee: buildEmployee({
            id: 'e1',
            departmentId: 'dept-eng',
            department: { id: 'dept-eng', name: 'Engineering' } as never,
          }),
          baseSalary: '60000.00',
        }),
        buildLineItem({
          id: 'item-eng-2',
          employee: buildEmployee({
            id: 'e2',
            departmentId: 'dept-eng',
            department: { id: 'dept-eng', name: 'Engineering' } as never,
          }),
          baseSalary: '50000.00',
        }),
        buildLineItem({
          id: 'item-no-dept',
          employee: buildEmployee({ id: 'e3' }),
          baseSalary: '20000.00',
        }),
        buildLineItem({
          id: 'item-freelancer',
          employeeId: null,
          employee: null,
          freelancerId: 'freelancer-1',
          freelancer: buildFreelancer(),
          baseSalary: '30000.00',
        }),
      ]);

      const result = await service.getRun('run-1');

      expect(result.departmentTotals).toEqual([
        {
          departmentId: 'dept-eng',
          departmentName: 'Engineering',
          totalNetPay: 110000,
          itemCount: 2,
        },
        {
          departmentId: null,
          departmentName: 'Freelancers',
          totalNetPay: 30000,
          itemCount: 1,
        },
        {
          departmentId: null,
          departmentName: 'Unassigned',
          totalNetPay: 20000,
          itemCount: 1,
        },
      ]);
    });
  });

  describe('getPayslipPdf', () => {
    it('rejects a run that is not Paid', async () => {
      runRepository.findById.mockResolvedValue(
        buildRun({ status: PayrollRunStatus.FINALIZED }),
      );

      await expect(service.getPayslipPdf('run-1', 'item-1')).rejects.toThrow(
        BadRequestException,
      );
    });

    it('rejects a freelancer line item', async () => {
      runRepository.findById.mockResolvedValue(
        buildRun({ status: PayrollRunStatus.PAID }),
      );
      lineItemRepository.findById.mockResolvedValue(
        buildLineItem({
          employeeId: null,
          employee: null,
          freelancerId: 'freelancer-1',
          freelancer: buildFreelancer(),
        }),
      );

      await expect(service.getPayslipPdf('run-1', 'item-1')).rejects.toThrow(
        BadRequestException,
      );
    });

    it("generates a PDF buffer for a Paid run's employee line item", async () => {
      runRepository.findById.mockResolvedValue(
        buildRun({ status: PayrollRunStatus.PAID }),
      );
      lineItemRepository.findById.mockResolvedValue(
        buildLineItem({
          employee: buildEmployee({
            employeeCode: 'ZC-00007',
            joiningDate: '2024-01-01',
          }),
        }),
      );

      const result = await service.getPayslipPdf('run-1', 'item-1');

      expect(result.buffer).toBeInstanceOf(Buffer);
      expect(result.buffer.length).toBeGreaterThan(0);
      expect(result.filename).toBe('Payslip-ZC-00007-2026-08.pdf');
    });
  });

  describe('getMyPayslips', () => {
    it('returns an empty list when the caller has no employee profile', async () => {
      employeeRepository.findByUserId.mockResolvedValue(null);

      const result = await service.getMyPayslips('user-x');

      expect(result).toEqual([]);
    });

    it("returns only the caller's own line items from Paid runs, newest period first", async () => {
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'employee-1' }),
      );
      runRepository.findAll.mockResolvedValue([
        buildRun({
          id: 'run-jan',
          month: 1,
          year: 2026,
          status: PayrollRunStatus.PAID,
          paidAt: new Date('2026-02-01T00:00:00.000Z'),
        }),
        buildRun({
          id: 'run-feb',
          month: 2,
          year: 2026,
          status: PayrollRunStatus.PAID,
          paidAt: new Date('2026-03-01T00:00:00.000Z'),
        }),
        buildRun({
          id: 'run-mar-draft',
          month: 3,
          year: 2026,
          status: PayrollRunStatus.DRAFT,
        }),
      ]);
      lineItemRepository.findByRunId.mockImplementation((runId: string) => {
        if (runId === 'run-jan') {
          return Promise.resolve([
            buildLineItem({ id: 'item-jan', runId, employeeId: 'employee-1' }),
          ]);
        }
        if (runId === 'run-feb') {
          return Promise.resolve([
            buildLineItem({ id: 'item-feb', runId, employeeId: 'employee-1' }),
            buildLineItem({
              id: 'item-other',
              runId,
              employeeId: 'someone-else',
            }),
          ]);
        }
        return Promise.resolve([]);
      });

      const result = await service.getMyPayslips('user-1');

      expect(result).toEqual([
        expect.objectContaining({
          runId: 'run-feb',
          lineItemId: 'item-feb',
          month: 2,
          year: 2026,
        }),
        expect.objectContaining({
          runId: 'run-jan',
          lineItemId: 'item-jan',
          month: 1,
          year: 2026,
        }),
      ]);
    });
  });

  describe('getEmployeePayslips', () => {
    it("returns a given employee's own line items from Paid runs, newest period first", async () => {
      runRepository.findAll.mockResolvedValue([
        buildRun({
          id: 'run-jan',
          month: 1,
          year: 2026,
          status: PayrollRunStatus.PAID,
          paidAt: new Date('2026-02-01T00:00:00.000Z'),
        }),
        buildRun({
          id: 'run-feb',
          month: 2,
          year: 2026,
          status: PayrollRunStatus.PAID,
          paidAt: new Date('2026-03-01T00:00:00.000Z'),
        }),
      ]);
      lineItemRepository.findByRunId.mockImplementation((runId: string) => {
        if (runId === 'run-jan') {
          return Promise.resolve([
            buildLineItem({ id: 'item-jan', runId, employeeId: 'employee-1' }),
          ]);
        }
        if (runId === 'run-feb') {
          return Promise.resolve([
            buildLineItem({ id: 'item-feb', runId, employeeId: 'employee-1' }),
            buildLineItem({
              id: 'item-other',
              runId,
              employeeId: 'someone-else',
            }),
          ]);
        }
        return Promise.resolve([]);
      });

      const result = await service.getEmployeePayslips('employee-1');

      expect(result).toEqual([
        expect.objectContaining({
          runId: 'run-feb',
          lineItemId: 'item-feb',
          month: 2,
          year: 2026,
        }),
        expect.objectContaining({
          runId: 'run-jan',
          lineItemId: 'item-jan',
          month: 1,
          year: 2026,
        }),
      ]);
    });

    it('returns an empty list for an employee with no Paid line items', async () => {
      runRepository.findAll.mockResolvedValue([]);

      const result = await service.getEmployeePayslips('employee-1');

      expect(result).toEqual([]);
    });
  });

  describe('getMyPayslipPdf', () => {
    it("refuses a line item that is not the caller's own", async () => {
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'employee-1' }),
      );
      lineItemRepository.findById.mockResolvedValue(
        buildLineItem({ employeeId: 'someone-else' }),
      );

      await expect(service.getMyPayslipPdf('user-1', 'item-1')).rejects.toThrow(
        NotFoundException,
      );
    });

    it("generates the caller's own payslip PDF", async () => {
      employeeRepository.findByUserId.mockResolvedValue(
        buildEmployee({ id: 'employee-1' }),
      );
      lineItemRepository.findById.mockResolvedValue(
        buildLineItem({
          employeeId: 'employee-1',
          employee: buildEmployee({
            id: 'employee-1',
            employeeCode: 'ZC-00007',
            joiningDate: '2024-01-01',
          }),
        }),
      );
      runRepository.findById.mockResolvedValue(
        buildRun({ status: PayrollRunStatus.PAID }),
      );

      const result = await service.getMyPayslipPdf('user-1', 'item-1');

      expect(result.buffer).toBeInstanceOf(Buffer);
      expect(result.filename).toBe('Payslip-ZC-00007-2026-08.pdf');
    });
  });
});
