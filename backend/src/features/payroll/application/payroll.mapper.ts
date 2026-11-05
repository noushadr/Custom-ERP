import { PayrollLineItem } from '../domain/entities/payroll-line-item.entity';
import { PayrollRun } from '../domain/entities/payroll-run.entity';
import {
  PayrollDepartmentTotal,
  PayrollLineItemResponseDto,
  PayrollRunDetailDto,
  PayrollRunSummaryDto,
} from './payroll-response.interface';

/** Pay is always worked out over 30 calendar days. */
export const DAYS_PER_MONTH = 30;
/** ...and 8 working hours a day when pricing an hour. */
export const HOURS_PER_DAY = 8;

export function toPayrollLineItemResponse(
  item: PayrollLineItem,
): PayrollLineItemResponseDto {
  const isFreelancer = item.freelancerId != null;
  const employeeName = isFreelancer
    ? item.freelancer!.fullName
    : `${item.employee!.firstName} ${item.employee!.lastName}`;
  const employeePhotoUrl = isFreelancer
    ? null
    : (item.employee!.profilePhotoUrl ?? null);

  const baseSalary = Number(item.baseSalary);
  const lateDeductionDays = isFreelancer ? 0 : item.lateDeductionDays;
  // Always 30 calendar days, whatever the month's real length.
  const lateDeduction = Math.round(
    (lateDeductionDays * baseSalary) / DAYS_PER_MONTH,
  );
  const absentDays = isFreelancer ? 0 : item.absentDays;
  const absentDeduction = Math.round((absentDays * baseSalary) / DAYS_PER_MONTH);
  const advanceSalary = Number(item.advanceSalary);
  const lateHours = isFreelancer ? 0 : Number(item.lateHours);
  const lateHoursDeduction = Math.round(
    (lateHours * baseSalary) / DAYS_PER_MONTH / HOURS_PER_DAY,
  );
  const toEntries = (list: { description: string; amount: number }[]) =>
    (list ?? []).map((entry) => ({
      description: entry.description,
      amount: Number(entry.amount),
    }));
  const sumOf = (list: { amount: number }[]) =>
    list.reduce((sum, entry) => sum + entry.amount, 0);
  const fines = toEntries(item.fines);
  const finesTotal = sumOf(fines);
  const freelanceTasks = toEntries(item.freelanceTasks);
  const freelanceTotal = sumOf(freelanceTasks);

  return {
    id: item.id,
    employeeId: item.employeeId ?? null,
    freelancerId: item.freelancerId ?? null,
    isFreelancer,
    employeeName,
    employeePhotoUrl,
    baseSalary,
    lateDays: isFreelancer ? 0 : item.lateDays,
    lateDeductionDays,
    lateDeduction,
    absentDays,
    absentDeduction,
    advanceSalary,
    lateHours,
    lateHoursDeduction,
    fines,
    finesTotal,
    freelanceTasks,
    freelanceTotal,
    netPay:
      baseSalary -
      lateDeduction -
      lateHoursDeduction -
      absentDeduction -
      advanceSalary -
      finesTotal +
      freelanceTotal,
    notes: item.notes ?? null,
  };
}

/** Groups this run's line items by department (freelancers into their own
 * "Freelancers" bucket, employees with no department into "Unassigned"),
 * summing each bucket's computed netPay — sorted highest-total first, same
 * convention as `EmployeesService.getPayrollSummary`'s dashboard-wide
 * department breakdown. */
export function toPayrollDepartmentTotals(
  lineItems: PayrollLineItem[],
): PayrollDepartmentTotal[] {
  const totalsByKey = new Map<string, PayrollDepartmentTotal>();

  lineItems.forEach((item) => {
    const key =
      item.freelancerId != null
        ? 'freelancers'
        : (item.employee?.departmentId ?? 'unassigned');
    const departmentName =
      item.freelancerId != null
        ? 'Freelancers'
        : (item.employee?.department?.name ?? 'Unassigned');
    const netPay = toPayrollLineItemResponse(item).netPay;

    const existing = totalsByKey.get(key);
    if (existing) {
      existing.totalNetPay += netPay;
      existing.itemCount += 1;
    } else {
      totalsByKey.set(key, {
        departmentId:
          item.freelancerId != null
            ? null
            : (item.employee?.departmentId ?? null),
        departmentName,
        totalNetPay: netPay,
        itemCount: 1,
      });
    }
  });

  return [...totalsByKey.values()].sort(
    (a, b) => b.totalNetPay - a.totalNetPay,
  );
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
    departmentTotals: toPayrollDepartmentTotals(lineItems),
  };
}
