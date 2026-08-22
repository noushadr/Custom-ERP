/// A finances-specific snapshot over [from, to] — mirrors the backend's
/// FinancialSummaryDto. Deliberately excludes revenue/cost/profit figures
/// that Agency Reporting already owns — see the backend's doc comment.
/// [currentMonthlyPayroll] and the outstanding-invoice figures are live
/// snapshots, not scoped to the range.
class FinancialSummary {
  const FinancialSummary({
    required this.from,
    required this.to,
    required this.deductions,
    required this.totalExpenses,
    required this.expensesByCategory,
    required this.currentMonthlyPayroll,
    required this.outstandingInvoicesTotal,
    required this.outstandingInvoicesCount,
  });

  final String from;
  final String to;
  final double deductions;
  final double totalExpenses;
  final Map<String, double> expensesByCategory;
  final double currentMonthlyPayroll;
  final double outstandingInvoicesTotal;
  final int outstandingInvoicesCount;
}
