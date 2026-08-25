class FinancialRecord {
  const FinancialRecord({
    required this.id,
    required this.year,
    required this.month,
    required this.revenueRs,
    required this.revenueUsd,
    required this.expenseRs,
    required this.expenseUsd,
    required this.fxRate,
    required this.profitRs,
    required this.profitUsd,
    required this.profitPercent,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int year;

  /// 1-12.
  final int month;

  final double revenueRs;
  final double revenueUsd;
  final double expenseRs;
  final double expenseUsd;

  /// PKR-per-USD rate for the month, reference only.
  final double fxRate;

  /// Computed server-side (revenue - expense) — never entered directly.
  final double profitRs;
  final double profitUsd;

  /// Profit as a percentage of revenue; 0 when revenue is 0.
  final double profitPercent;

  final DateTime createdAt;
  final DateTime updatedAt;
}
