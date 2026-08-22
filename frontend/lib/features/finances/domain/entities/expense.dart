class Expense {
  const Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.payeeName,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// One of ExpenseCategory's values.
  final String category;
  final double amount;

  /// ISO date (yyyy-MM-dd).
  final String date;
  final String? payeeName;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
}
