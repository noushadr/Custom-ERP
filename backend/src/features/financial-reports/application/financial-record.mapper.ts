import { FinancialRecord } from '../domain/entities/financial-record.entity';
import { FinancialRecordResponseDto } from './financial-record-response.interface';

export function toFinancialRecordResponse(
  record: FinancialRecord,
): FinancialRecordResponseDto {
  const revenueRs = Number(record.revenueRs);
  const revenueUsd = Number(record.revenueUsd);
  const expenseRs = Number(record.expenseRs);
  const expenseUsd = Number(record.expenseUsd);
  const profitRs = revenueRs - expenseRs;
  const profitUsd = revenueUsd - expenseUsd;

  return {
    id: record.id,
    year: record.year,
    month: record.month,
    revenueRs,
    revenueUsd,
    expenseRs,
    expenseUsd,
    fxRate: Number(record.fxRate),
    profitRs,
    profitUsd,
    profitPercent: revenueRs === 0 ? 0 : (profitRs / revenueRs) * 100,
    createdAt: record.createdAt.toISOString(),
    updatedAt: record.updatedAt.toISOString(),
  };
}
