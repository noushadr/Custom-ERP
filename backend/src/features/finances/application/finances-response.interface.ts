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

/** A finances-specific snapshot over [from, to] — deliberately excludes
 * revenue/cost/profit figures that Agency Reporting already owns
 * (`totalRevenue`/`totalCost`/`netProfit` there), since showing the same
 * concept under the same or a near-identical label on two pages either
 * duplicates a number exactly (revenue, project cost) or — worse — shows a
 * *different* number under an identical "Net Profit" label (Agency's
 * excludes operating expenses, Finances' didn't), which reads as a bug
 * rather than a deliberate distinction. `deductions`/`totalExpenses`/
 * `expensesByCategory` are scoped to that range; `currentMonthlyPayroll`
 * and `outstandingInvoices*` are live snapshots (like Agency Reporting's
 * MRR). */
export interface FinancialSummaryDto {
  from: string;
  to: string;
  /** The aggregate of `originalClientPrice - netPrice` across in-range
   * projects — the existing per-project deduction %, reported here rather
   * than tracked as a separate taxes/commissions entity. */
  deductions: number;
  totalExpenses: number;
  expensesByCategory: Record<string, number>;
  currentMonthlyPayroll: number;
  outstandingInvoicesTotal: number;
  outstandingInvoicesCount: number;
}
