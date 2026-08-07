class SalaryRecord {
  const SalaryRecord({
    required this.id,
    required this.amount,
    required this.effectiveDate,
    this.note,
    required this.createdAt,
  });

  final String id;
  final double amount;

  /// ISO 'YYYY-MM-DD' — the date this amount took effect.
  final String effectiveDate;
  final String? note;
  final DateTime createdAt;
}
