export interface ExpenseResponseDto {
  id: string;
  category: string;
  amount: number;
  date: string;
  payeeName: string | null;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

/** A P&L-style snapshot over [from, to]. `grossRevenue`/`deductions`/
 * `projectCosts`/`totalExpenses`/`expensesByCategory`/`netProfit` are scoped
 * to that range; `currentMonthlyPayroll` and `outstandingInvoices*` are live
 * snapshots (like Agency Reporting's MRR) and deliberately excluded from
 * `netProfit` — folding a live monthly figure into a range-scoped total
 * would misrepresent a range that isn't "this month". */
export interface FinancialSummaryDto {
  from: string;
  to: string;
  grossRevenue: number;
  /** The aggregate of `originalClientPrice - netPrice` across in-range
   * projects — the existing per-project deduction %, reported here rather
   * than tracked as a separate taxes/commissions entity. */
  deductions: number;
  projectCosts: number;
  totalExpenses: number;
  expensesByCategory: Record<string, number>;
  netProfit: number;
  currentMonthlyPayroll: number;
  outstandingInvoicesTotal: number;
  outstandingInvoicesCount: number;
}
