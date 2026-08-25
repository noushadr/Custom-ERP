export interface FinancialRecordResponseDto {
  id: string;
  year: number;
  month: number;
  revenueRs: number;
  revenueUsd: number;
  expenseRs: number;
  expenseUsd: number;
  fxRate: number;
  profitRs: number;
  profitUsd: number;
  /** Profit as a percentage of revenue; 0 when revenue is 0. */
  profitPercent: number;
  createdAt: string;
  updatedAt: string;
}
