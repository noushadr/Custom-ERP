import { PayrollLineItem } from '../domain/entities/payroll-line-item.entity';
import { PayrollRun } from '../domain/entities/payroll-run.entity';
import {
  PayrollLineItemResponseDto,
  PayrollRunDetailDto,
  PayrollRunSummaryDto,
} from './payroll-response.interface';

export function toPayrollLineItemResponse(
  item: PayrollLineItem,
): PayrollLineItemResponseDto {
  const baseSalary = Number(item.baseSalary);
  const bonuses = Number(item.bonuses);
  const allowances = Number(item.allowances);
  const overtime = Number(item.overtime);
  const deductions = Number(item.deductions);
  const advances = Number(item.advances);
  const tax = Number(item.tax);

  return {
    id: item.id,
    employeeId: item.employeeId,
    employeeName: `${item.employee.firstName} ${item.employee.lastName}`,
    employeePhotoUrl: item.employee.profilePhotoUrl ?? null,
    baseSalary,
    bonuses,
    allowances,
    overtime,
    deductions,
    advances,
    tax,
    netPay:
      baseSalary + bonuses + allowances + overtime - deductions - advances - tax,
    notes: item.notes ?? null,
  };
}

export function toPayrollRunSummary(
  run: PayrollRun,
  lineItems: PayrollLineItem[],
): PayrollRunSummaryDto {
  const totalNetPay = lineItems
    .map(toPayrollLineItemResponse)
    .reduce((sum, item) => sum + item.netPay, 0);

  return {
    id: run.id,
    month: run.month,
    year: run.year,
    status: run.status,
    employeeCount: lineItems.length,
    totalNetPay,
    generatedByName: run.generatedByName,
    finalizedByName: run.finalizedByName ?? null,
    finalizedAt: run.finalizedAt?.toISOString() ?? null,
    paidByName: run.paidByName ?? null,
    paidAt: run.paidAt?.toISOString() ?? null,
    createdAt: run.createdAt.toISOString(),
  };
}

export function toPayrollRunDetail(
  run: PayrollRun,
  lineItems: PayrollLineItem[],
): PayrollRunDetailDto {
  return {
    ...toPayrollRunSummary(run, lineItems),
    lineItems: lineItems.map(toPayrollLineItemResponse),
  };
}
