import { PayrollLineItem } from '../domain/entities/payroll-line-item.entity';
import { PayrollRun } from '../domain/entities/payroll-run.entity';
import {
  PayrollLineItemResponseDto,
  PayrollRunDetailDto,
  PayrollRunSummaryDto,
} from './payroll-response.interface';

/** Every rate-based deduction in this app's real payroll process divides
 * by a flat 30-day month, regardless of the actual calendar days in the
 * run's month — mirrored here exactly rather than using real days-in-
 * month. */
const DAYS_PER_MONTH = 30;
const HOURS_PER_DAY = 8;

export function toPayrollLineItemResponse(
  item: PayrollLineItem,
): PayrollLineItemResponseDto {
  const salarySnapshot = Number(item.baseSalary);
  const quantity = item.quantity ?? null;
  const perUnitRate = item.perUnitRate != null ? Number(item.perUnitRate) : null;
  const baseSalary =
    quantity != null && quantity > 0 && perUnitRate != null
      ? quantity * perUnitRate
      : salarySnapshot;

  const allowances = Number(item.allowances);
  const overtime = Number(item.overtime);
  const reimbursement = Number(item.reimbursement);
  const commissions = Number(item.commissions);
  const deductions = Number(item.deductions);
  const advances = Number(item.advances);
  const tax = Number(item.tax);
  const fines = Number(item.fines);

  const dailyRate = baseSalary / DAYS_PER_MONTH;
  const hourlyRate = dailyRate / HOURS_PER_DAY;

  const absentDeductionRs = Math.round(item.totalAbsent * dailyRate * 100) / 100;
  const lateHoursDeductionRs =
    Math.round(item.lateHours * hourlyRate * 100) / 100;
  const unpaidOffs = Math.floor(item.lateDays / 3);
  const lateDaysDeductionRs = Math.round(unpaidOffs * dailyRate * 100) / 100;

  const netPay =
    baseSalary +
    allowances +
    overtime +
    reimbursement +
    commissions -
    deductions -
    advances -
    tax -
    fines -
    absentDeductionRs -
    lateHoursDeductionRs -
    lateDaysDeductionRs;

  return {
    id: item.id,
    employeeId: item.employeeId,
    employeeName: `${item.employee.firstName} ${item.employee.lastName}`,
    employeePhotoUrl: item.employee.profilePhotoUrl ?? null,
    baseSalary,
    quantity,
    perUnitRate,
    allowances,
    overtime,
    reimbursement,
    commissions,
    deductions,
    advances,
    tax,
    fines,
    totalAbsent: item.totalAbsent,
    absentDeductionRs,
    lateHours: item.lateHours,
    lateHoursDeductionRs,
    lateDays: item.lateDays,
    lateDaysDeductionRs,
    netPay,
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
