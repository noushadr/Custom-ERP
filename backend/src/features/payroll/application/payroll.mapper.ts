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
  const isFreelancer = item.freelancerId != null;
  const employeeName = isFreelancer
    ? item.freelancer!.fullName
    : `${item.employee!.firstName} ${item.employee!.lastName}`;
  const employeePhotoUrl = isFreelancer
    ? null
    : (item.employee!.profilePhotoUrl ?? null);

  const salarySnapshot = Number(item.baseSalary);
  const quantity = item.quantity ?? null;
  const perUnitRate = item.perUnitRate != null ? Number(item.perUnitRate) : null;
  const baseSalary =
    quantity != null && quantity > 0 && perUnitRate != null
      ? quantity * perUnitRate
      : salarySnapshot;

  return {
    id: item.id,
    employeeId: item.employeeId ?? null,
    freelancerId: item.freelancerId ?? null,
    isFreelancer,
    employeeName,
    employeePhotoUrl,
    baseSalary,
    quantity,
    perUnitRate,
    netPay: Number(item.netPay),
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
