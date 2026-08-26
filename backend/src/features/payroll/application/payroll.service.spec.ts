import { BadRequestException, ConflictException, NotFoundException } from '@nestjs/common';
import type { UserRepository } from '../../authentication/domain/repositories/user-repository.interface';
import { Employee } from '../../employee/domain/entities/employee.entity';
import { EmployeesService } from '../../employee/application/employees.service';
import { EmploymentStatus } from '../../employee/domain/enums/employment-status.enum';
import type { EmployeeRepository } from '../../employee/domain/repositories/employee-repository.interface';
import { PayrollLineItem } from '../domain/entities/payroll-line-item.entity';
import { PayrollRun } from '../domain/entities/payroll-run.entity';
import { PayrollRunStatus } from '../domain/enums/payroll-run-status.enum';
import type { PayrollLineItemRepository } from '../domain/repositories/payroll-line-item-repository.interface';
import type { PayrollRunRepository } from '../domain/repositories/payroll-run-repository.interface';
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

function buildLineItem(overrides: Partial<PayrollLineItem> = {}): PayrollLineItem {
  return {
    id: 'item-1',
    runId: 'run-1',
    employeeId: 'employee-1',
    employee: buildEmployee(),
    baseSalary: '50000.00',
    quantity: null,
    perUnitRate: null,
    allowances: '0.00',
    overtime: '0.00',
    reimbursement: '0.00',
    commissions: '0.00',
    deductions: '0.00',
    advances: '0.00',
    tax: '0.00',
    fines: '0.00',
    totalAbsent: 0,
    lateHours: 0,
    lateDays: 0,
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
  let employeesService: jest.Mocked<EmployeesService>;
  let notificationsService: jest.Mocked<NotificationsService>;

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
    employeesService = {
      getSalaryAsOf: jest.fn().mockResolvedValue(0),
    } as unknown as jest.Mocked<EmployeesService>;
    notificationsService = {
      create: jest.fn(),
    } as unknown as jest.Mocked<NotificationsService>;

    service = new PayrollService(
      runRepository,
      lineItemRepository,
      employeeRepository,
      userRepository,
      employeesService,
      notificationsService,
    );
  });

  describe('generateRun', () => {
    it('creates a run and one line item per active employee, with baseSalary as of that month', async () => {
      employeeRepository.findAll.mockResolvedValue([
        buildEmployee({ id: 'e1', employmentStatus: EmploymentStatus.ACTIVE }),
        buildEmployee({ id: 'e2', employmentStatus: EmploymentStatus.RESIGNED }),
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

    it('throws ConflictException when a run already exists for that month/year', async () => {
      runRepository.findByMonthYear.mockResolvedValue(buildRun());

      await expect(
        service.generateRun({ month: 8, year: 2026 }, 'admin-1'),
      ).rejects.toBeInstanceOf(ConflictException);
    });
  });

  describe('updateLineItem', () => {
    it('updates the adjustment fields and recomputes netPay', async () => {
      runRepository.findById.mockResolvedValue(buildRun({ status: PayrollRunStatus.DRAFT }));
      lineItemRepository.findById.mockResolvedValue(buildLineItem());
      lineItemRepository.findByRunId.mockResolvedValue([
        buildLineItem({
          baseSalary: '50000.00',
          deductions: '1000.00',
          fines: '500.00',
        }),
      ]);

      const result = await service.updateLineItem('run-1', 'item-1', {
        deductions: 1000,
        fines: 500,
      });

      expect(result.lineItems[0].netPay).toBe(48500); // 50000 - 1000 - 500
    });

    it('deducts one day of salary for every 3 late-arrival days (flat 30-day month)', async () => {
      runRepository.findById.mockResolvedValue(buildRun({ status: PayrollRunStatus.DRAFT }));
      lineItemRepository.findById.mockResolvedValue(buildLineItem());
      lineItemRepository.findByRunId.mockResolvedValue([
        buildLineItem({ baseSalary: '30000.00', lateDays: 3 }), // 1,000/day
      ]);

      const result = await service.updateLineItem('run-1', 'item-1', {
        lateDays: 3,
      });

      expect(result.lineItems[0].lateDays).toBe(3);
      expect(result.lineItems[0].lateDaysDeductionRs).toBe(1000); // floor(3/3) * 1000
      expect(result.lineItems[0].netPay).toBe(29000); // 30000 - 1000
    });

    it('does not deduct for fewer than 3 late-arrival days', async () => {
      runRepository.findById.mockResolvedValue(buildRun({ status: PayrollRunStatus.DRAFT }));
      lineItemRepository.findById.mockResolvedValue(buildLineItem());
      lineItemRepository.findByRunId.mockResolvedValue([
        buildLineItem({ baseSalary: '30000.00', lateDays: 2 }),
      ]);

      const result = await service.updateLineItem('run-1', 'item-1', {
        lateDays: 2,
      });

      expect(result.lineItems[0].lateDaysDeductionRs).toBe(0); // floor(2/3) = 0
      expect(result.lineItems[0].netPay).toBe(30000);
    });

    it('deducts late hours at the flat hourly rate (baseSalary / 30 / 8)', async () => {
      runRepository.findById.mockResolvedValue(buildRun({ status: PayrollRunStatus.DRAFT }));
      lineItemRepository.findById.mockResolvedValue(buildLineItem());
      lineItemRepository.findByRunId.mockResolvedValue([
        buildLineItem({ baseSalary: '24000.00', lateHours: 5 }), // 100/hour
      ]);

      const result = await service.updateLineItem('run-1', 'item-1', {
        lateHours: 5,
      });

      expect(result.lineItems[0].lateHoursDeductionRs).toBe(500); // 5 * 100
      expect(result.lineItems[0].netPay).toBe(23500);
    });

    it('deducts full absence days at the flat daily rate', async () => {
      runRepository.findById.mockResolvedValue(buildRun({ status: PayrollRunStatus.DRAFT }));
      lineItemRepository.findById.mockResolvedValue(buildLineItem());
      lineItemRepository.findByRunId.mockResolvedValue([
        buildLineItem({ baseSalary: '30000.00', totalAbsent: 2 }), // 1,000/day
      ]);

      const result = await service.updateLineItem('run-1', 'item-1', {
        totalAbsent: 2,
      });

      expect(result.lineItems[0].absentDeductionRs).toBe(2000);
      expect(result.lineItems[0].netPay).toBe(28000);
    });

    it('adds reimbursement and commissions to net pay', async () => {
      runRepository.findById.mockResolvedValue(buildRun({ status: PayrollRunStatus.DRAFT }));
      lineItemRepository.findById.mockResolvedValue(buildLineItem());
      lineItemRepository.findByRunId.mockResolvedValue([
        buildLineItem({
          baseSalary: '30000.00',
          reimbursement: '7000.00',
          commissions: '1500.00',
        }),
      ]);

      const result = await service.updateLineItem('run-1', 'item-1', {
        reimbursement: 7000,
        commissions: 1500,
      });

      expect(result.lineItems[0].netPay).toBe(38500); // 30000 + 7000 + 1500
    });

    it("computes a piece-rate employee's base pay as quantity * perUnitRate, replacing the salary snapshot", async () => {
      runRepository.findById.mockResolvedValue(buildRun({ status: PayrollRunStatus.DRAFT }));
      lineItemRepository.findById.mockResolvedValue(buildLineItem());
      lineItemRepository.findByRunId.mockResolvedValue([
        buildLineItem({
          baseSalary: '0.00',
          quantity: 5,
          perUnitRate: '1000.00',
        }),
      ]);

      const result = await service.updateLineItem('run-1', 'item-1', {
        quantity: 5,
        perUnitRate: 1000,
      });

      expect(result.lineItems[0].baseSalary).toBe(5000);
      expect(result.lineItems[0].netPay).toBe(5000);
    });

    it('rejects editing a line item once the run is no longer draft', async () => {
      runRepository.findById.mockResolvedValue(
        buildRun({ status: PayrollRunStatus.FINALIZED }),
      );

      await expect(
        service.updateLineItem('run-1', 'item-1', { fines: 100 }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('throws NotFoundException for a line item belonging to a different run', async () => {
      runRepository.findById.mockResolvedValue(buildRun());
      lineItemRepository.findById.mockResolvedValue(
        buildLineItem({ runId: 'some-other-run' }),
      );

      await expect(
        service.updateLineItem('run-1', 'item-1', { fines: 100 }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  describe('finalizeRun', () => {
    it('moves a draft run to finalized and stamps the actor', async () => {
      runRepository.findById.mockResolvedValue(buildRun({ status: PayrollRunStatus.DRAFT }));
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

      await expect(service.finalizeRun('run-1', 'admin-1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
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
        buildLineItem({ id: 'item-2', employee: buildEmployee({ userId: 'user-b' }) }),
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
  });

  describe('getRuns', () => {
    it('returns a summary with totalNetPay across all line items', async () => {
      runRepository.findAll.mockResolvedValue([buildRun()]);
      lineItemRepository.findByRunId.mockResolvedValue([
        buildLineItem({ baseSalary: '50000.00', allowances: '2000.00' }),
        buildLineItem({ id: 'item-2', baseSalary: '60000.00' }),
      ]);

      const result = await service.getRuns();

      expect(result[0].employeeCount).toBe(2);
      expect(result[0].totalNetPay).toBe(112000); // 52000 + 60000
    });
  });
});
