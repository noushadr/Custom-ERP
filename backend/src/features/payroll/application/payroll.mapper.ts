import { PayrollLineItem } from '../domain/entities/payroll-line-item.entity';
import { PayrollRun } from '../domain/entities/payroll-run.entity';
import {
  PayrollLineItemResponseDto,
  PayrollRunDetailDto,
  PayrollRunSummaryDto,
} from './payroll-response.interface';

/** Calendar days in [month] (1-12) of [year] — plain arithmetic, no
 * Date-to-string timezone conversion involved. */
function daysInMonth(year: number, month: number): number {
  return new Date(year, month, 0).getDate();
}

export function toPayrollLineItemResponse(
  item: PayrollLineItem,
  run: PayrollRun,
): PayrollLineItemResponseDto {
  const baseSalary = Number(item.baseSalary);
  const allowances = Number(item.allowances);
  const overtime = Number(item.overtime);
  const deductions = Number(item.deductions);
  const advances = Number(item.advances);
  const tax = Number(item.tax);
  const fines = Number(item.fines);

  const unpaidOffs = Math.floor(item.lateCount / 3);
  const dailyRate = baseSalary / daysInMonth(run.year, run.month);
  const lateDeductionRs = Math.round(unpaidOffs * dailyRate * 100) / 100;

  return {
    id: item.id,
    employeeId: item.employeeId,
    employeeName: `${item.employee.firstName} ${item.employee.lastName}`,
    employeePhotoUrl: item.employee.profilePhotoUrl ?? null,
    baseSalary,
    allowances,
    overtime,
    deductions,
    advances,
    tax,
    fines,
    lateCount: item.lateCount,
    lateDeductionRs,
    netPay:
      baseSalary +
      allowances +
      overtime -
      deductions -
      advances -
      tax -
      fines -
      lateDeductionRs,
    notes: item.notes ?? null,
  };
}

export function toPayrollRunSummary(
  run: PayrollRun,
  lineItems: PayrollLineItem[],
): PayrollRunSummaryDto {
  const totalNetPay = lineItems
    .map((item) => toPayrollLineItemResponse(item, run))
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
    lineItems: lineItems.map((item) => toPayrollLineItemResponse(item, run)),
  };
}
