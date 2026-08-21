/// A P&L-style snapshot over [from, to] — mirrors the backend's
/// FinancialSummaryDto. [currentMonthlyPayroll] and the outstanding-invoice
/// figures are live snapshots, not scoped to the range, and are
/// deliberately excluded from [netProfit] — see the backend's doc comment.
class FinancialSummary {
  const FinancialSummary({
    required this.from,
    required this.to,
    required this.grossRevenue,
    required this.deductions,
    required this.projectCosts,
    required this.totalExpenses,
    required this.expensesByCategory,
    required this.netProfit,
    required this.currentMonthlyPayroll,
    required this.outstandingInvoicesTotal,
    required this.outstandingInvoicesCount,
  });

  final String from;
  final String to;
  final double grossRevenue;
  final double deductions;
  final double projectCosts;
  final double totalExpenses;
  final Map<String, double> expensesByCategory;
  final double netProfit;
  final double currentMonthlyPayroll;
  final double outstandingInvoicesTotal;
  final int outstandingInvoicesCount;
}
