import { NotFoundException } from '@nestjs/common';
import { ProjectResponseDto } from '../../clients/application/client-response.interface';
import { ClientsService } from '../../clients/application/clients.service';
import { ProjectPaymentStatus } from '../../clients/domain/enums/project-payment-status.enum';
import { ProjectStatus } from '../../clients/domain/enums/project-status.enum';
import { ProjectType } from '../../clients/domain/enums/project-type.enum';
import { EmployeesService } from '../../employee/application/employees.service';
import { Expense } from '../domain/entities/expense.entity';
import { ExpenseCategory } from '../domain/enums/expense-category.enum';
import type { ExpenseRepository } from '../domain/repositories/expense-repository.interface';
import { FinancesService } from './finances.service';

function buildProject(overrides: Partial<ProjectResponseDto> = {}): ProjectResponseDto {
  return {
    id: 'project-1',
    clientId: 'client-1',
    clientName: 'Acme Inc',
    name: 'Website Revamp',
    type: ProjectType.ONE_TIME,
    status: ProjectStatus.ACTIVE,
    startDate: '2026-03-01',
    endDate: null,
    renewalDate: null,
    originalClientPrice: 1000,
    deductionRate: 20,
    netPrice: 800,
    cost: 100,
    profit: 700,
    notes: null,
    paymentStatus: ProjectPaymentStatus.UNPAID,
    amountPaid: 0,
    assignedEmployees: [],
    targetDepartments: [],
    services: [],
    createdAt: '2026-03-01T00:00:00.000Z',
    updatedAt: '2026-03-01T00:00:00.000Z',
    ...overrides,
  };
}

function buildExpense(overrides: Partial<Expense> = {}): Expense {
  return {
    id: 'expense-1',
    category: ExpenseCategory.OTHER,
    amount: '100.00',
    date: '2026-03-10',
    createdAt: new Date('2026-03-10T00:00:00.000Z'),
    updatedAt: new Date('2026-03-10T00:00:00.000Z'),
    ...overrides,
  } as Expense;
}

describe('FinancesService', () => {
  let service: FinancesService;
  let expenseRepository: jest.Mocked<ExpenseRepository>;
  let clientsService: jest.Mocked<ClientsService>;
  let employeesService: jest.Mocked<EmployeesService>;

  beforeEach(() => {
    expenseRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      save: jest.fn((item) =>
        Promise.resolve({
          ...item,
          createdAt: item.createdAt ?? new Date('2026-01-01T00:00:00.000Z'),
          updatedAt: new Date('2026-01-01T00:00:00.000Z'),
        } as Expense),
      ),
    };
    clientsService = {
      getProjects: jest.fn().mockResolvedValue([]),
    } as unknown as jest.Mocked<ClientsService>;
    employeesService = {
      getPayrollSummary: jest.fn().mockResolvedValue({
        totalMonthlyPayroll: 0,
        dailyPayroll: 0,
        activeEmployeeCount: 0,
      }),
    } as unknown as jest.Mocked<EmployeesService>;

    service = new FinancesService(expenseRepository, clientsService, employeesService);
  });

  describe('expenses', () => {
    it('creates an expense', async () => {
      const result = await service.createExpense({
        category: ExpenseCategory.SOFTWARE_TOOLS,
        amount: 250,
        date: '2026-03-05',
        payeeName: 'Figma',
      });

      expect(result.category).toBe(ExpenseCategory.SOFTWARE_TOOLS);
      expect(result.amount).toBe(250);
      expect(result.payeeName).toBe('Figma');
    });

    it('updates an expense', async () => {
      expenseRepository.findById.mockResolvedValue(buildExpense());

      const result = await service.updateExpense('expense-1', { amount: 500 });

      expect(result.amount).toBe(500);
    });

    it('throws NotFoundException updating a missing expense', async () => {
      expenseRepository.findById.mockResolvedValue(null);
      await expect(
        service.updateExpense('missing', { amount: 1 }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('filters expenses by date range', async () => {
      expenseRepository.findAll.mockResolvedValue([
        buildExpense({ id: 'e1', date: '2026-02-15' }),
        buildExpense({ id: 'e2', date: '2026-03-15' }),
        buildExpense({ id: 'e3', date: '2026-04-15' }),
      ]);

      const result = await service.getExpenses('2026-03-01', '2026-03-31');

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('e2');
    });
  });

  describe('getFinancialSummary', () => {
    it('computes deductions and total expenses for the range', async () => {
      clientsService.getProjects.mockResolvedValue([
        buildProject({
          id: 'p1',
          startDate: '2026-03-10',
          originalClientPrice: 1000,
          netPrice: 800,
          cost: 100,
        }),
      ]);
      expenseRepository.findAll.mockResolvedValue([
        buildExpense({ date: '2026-03-12', amount: '50.00' }),
      ]);

      const summary = await service.getFinancialSummary('2026-03-01', '2026-03-31');

      expect(summary.deductions).toBe(200);
      expect(summary.totalExpenses).toBe(50);
    });

    it('groups expenses by category', async () => {
      expenseRepository.findAll.mockResolvedValue([
        buildExpense({ id: 'e1', category: ExpenseCategory.MARKETING, amount: '100.00', date: '2026-03-01' }),
        buildExpense({ id: 'e2', category: ExpenseCategory.MARKETING, amount: '50.00', date: '2026-03-02' }),
        buildExpense({ id: 'e3', category: ExpenseCategory.TAXES, amount: '75.00', date: '2026-03-03' }),
      ]);

      const summary = await service.getFinancialSummary('2026-03-01', '2026-03-31');

      expect(summary.expensesByCategory[ExpenseCategory.MARKETING]).toBe(150);
      expect(summary.expensesByCategory[ExpenseCategory.TAXES]).toBe(75);
    });

    it('excludes projects starting outside the range from deductions', async () => {
      clientsService.getProjects.mockResolvedValue([
        buildProject({
          id: 'p1',
          startDate: '2026-03-10',
          originalClientPrice: 1000,
          netPrice: 800,
        }),
        buildProject({
          id: 'p2',
          startDate: '2026-01-01',
          originalClientPrice: 20000,
          netPrice: 9999,
        }),
      ]);

      const summary = await service.getFinancialSummary('2026-03-01', '2026-03-31');

      expect(summary.deductions).toBe(200);
    });

    it('reports current monthly payroll as a live snapshot', async () => {
      employeesService.getPayrollSummary.mockResolvedValue({
        totalMonthlyPayroll: 500000,
        dailyPayroll: 16000,
        activeEmployeeCount: 10,
      });

      const summary = await service.getFinancialSummary('2026-03-01', '2026-03-31');

      expect(summary.currentMonthlyPayroll).toBe(500000);
    });

    it('sums outstanding balances across unpaid and partially-paid projects, regardless of range', async () => {
      clientsService.getProjects.mockResolvedValue([
        buildProject({
          id: 'p1',
          startDate: '2020-01-01', // outside the requested range
          netPrice: 1000,
          paymentStatus: ProjectPaymentStatus.UNPAID,
          amountPaid: 0,
        }),
        buildProject({
          id: 'p2',
          startDate: '2020-01-01',
          netPrice: 500,
          paymentStatus: ProjectPaymentStatus.PARTIAL,
          amountPaid: 200,
        }),
        buildProject({
          id: 'p3',
          startDate: '2020-01-01',
          netPrice: 300,
          paymentStatus: ProjectPaymentStatus.PAID,
          amountPaid: 300,
        }),
      ]);

      const summary = await service.getFinancialSummary('2026-03-01', '2026-03-31');

      expect(summary.outstandingInvoicesCount).toBe(2);
      expect(summary.outstandingInvoicesTotal).toBe(1300); // 1000 + (500-200)
    });

    it('defaults to the current month when no range is given', async () => {
      const summary = await service.getFinancialSummary();

      const now = new Date();
      const pad = (n: number) => String(n).padStart(2, '0');
      const isoDate = (d: Date) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

      expect(summary.from).toBe(isoDate(new Date(now.getFullYear(), now.getMonth(), 1)));
      expect(summary.to).toBe(isoDate(now));
    });
  });
});
