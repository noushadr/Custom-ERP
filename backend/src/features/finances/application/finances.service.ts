import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { definedFieldsOnly } from '../../../core/utils/defined-fields-only.util';
import { ClientsService } from '../../clients/application/clients.service';
import { ProjectPaymentStatus } from '../../clients/domain/enums/project-payment-status.enum';
import { EmployeesService } from '../../employee/application/employees.service';
import { CreateExpenseDto } from './dto/create-expense.dto';
import { UpdateExpenseDto } from './dto/update-expense.dto';
import { Expense } from '../domain/entities/expense.entity';
import {
  EXPENSE_REPOSITORY,
  type ExpenseRepository,
} from '../domain/repositories/expense-repository.interface';
import { ExpenseResponseDto, FinancialSummaryDto } from './finances-response.interface';
import { toExpenseResponse } from './finances.mapper';

/** Formats a Date's own local Y/M/D as 'YYYY-MM-DD' — see the identical
 * helper (and its reasoning) in AgencyReportingService. */
function toIsoDate(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

@Injectable()
export class FinancesService {
  constructor(
    @Inject(EXPENSE_REPOSITORY)
    private readonly expenseRepository: ExpenseRepository,
    private readonly clientsService: ClientsService,
    private readonly employeesService: EmployeesService,
  ) {}

  // ---- Expenses ----

  async getExpenses(from?: string, to?: string): Promise<ExpenseResponseDto[]> {
    const all = await this.expenseRepository.findAll();
    const filtered = this.filterInRange(all, from, to);
    return filtered.map(toExpenseResponse);
  }

  async createExpense(dto: CreateExpenseDto): Promise<ExpenseResponseDto> {
    const expense = new Expense();
    expense.category = dto.category;
    expense.amount = dto.amount.toFixed(2);
    expense.date = dto.date;
    expense.payeeName = dto.payeeName;
    expense.notes = dto.notes;

    const saved = await this.expenseRepository.save(expense);
    return toExpenseResponse(saved);
  }

  async updateExpense(id: string, dto: UpdateExpenseDto): Promise<ExpenseResponseDto> {
    const expense = await this.expenseRepository.findById(id);
    if (!expense) throw new NotFoundException('Expense not found');

    const changes = definedFieldsOnly(dto);
    if (changes.amount !== undefined) {
      expense.amount = changes.amount.toFixed(2);
    }
    expense.category = changes.category ?? expense.category;
    expense.date = changes.date ?? expense.date;
    if (changes.payeeName !== undefined) expense.payeeName = changes.payeeName;
    if (changes.notes !== undefined) expense.notes = changes.notes;

    const saved = await this.expenseRepository.save(expense);
    return toExpenseResponse(saved);
  }

  // ---- Summary ----

  async getFinancialSummary(from?: string, to?: string): Promise<FinancialSummaryDto> {
    const now = new Date();
    const resolvedFrom = from ?? toIsoDate(new Date(now.getFullYear(), now.getMonth(), 1));
    const resolvedTo = to ?? toIsoDate(now);

    const projects = await this.clientsService.getProjects({});
    const projectsInRange = this.filterInRange(projects, resolvedFrom, resolvedTo, (p) => p.startDate);

    let grossRevenue = 0;
    let deductions = 0;
    let projectCosts = 0;
    for (const project of projectsInRange) {
      grossRevenue += project.netPrice;
      deductions += project.originalClientPrice - project.netPrice;
      projectCosts += project.cost;
    }

    const allExpenses = await this.expenseRepository.findAll();
    const expensesInRange = this.filterInRange(allExpenses, resolvedFrom, resolvedTo);
    let totalExpenses = 0;
    const expensesByCategory: Record<string, number> = {};
    for (const expense of expensesInRange) {
      const amount = Number(expense.amount);
      totalExpenses += amount;
      expensesByCategory[expense.category] = (expensesByCategory[expense.category] ?? 0) + amount;
    }

    const netProfit = grossRevenue - projectCosts - totalExpenses;

    const payrollSummary = await this.employeesService.getPayrollSummary();

    let outstandingInvoicesTotal = 0;
    let outstandingInvoicesCount = 0;
    for (const project of projects) {
      if (project.paymentStatus === ProjectPaymentStatus.PAID) continue;
      const outstanding = Math.max(0, project.netPrice - project.amountPaid);
      if (outstanding > 0) {
        outstandingInvoicesTotal += outstanding;
        outstandingInvoicesCount += 1;
      }
    }

    return {
      from: resolvedFrom,
      to: resolvedTo,
      grossRevenue,
      deductions,
      projectCosts,
      totalExpenses,
      expensesByCategory,
      netProfit,
      currentMonthlyPayroll: payrollSummary.totalMonthlyPayroll,
      outstandingInvoicesTotal,
      outstandingInvoicesCount,
    };
  }

  private filterInRange<T>(
    items: T[],
    from: string | undefined,
    to: string | undefined,
    dateOf: (item: T) => string = (item) => (item as { date: string }).date,
  ): T[] {
    if (!from && !to) return items;
    const fromDate = from ? new Date(from) : null;
    const toDate = to ? new Date(to) : null;
    if (toDate) toDate.setHours(23, 59, 59, 999);

    return items.filter((item) => {
      const date = new Date(dateOf(item));
      if (fromDate && date < fromDate) return false;
      if (toDate && date > toDate) return false;
      return true;
    });
  }
}
