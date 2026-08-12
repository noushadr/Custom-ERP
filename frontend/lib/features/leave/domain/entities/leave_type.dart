class LeaveType {
  const LeaveType({
    required this.id,
    required this.name,
    required this.annualAllowanceDays,
    this.carryForwardLimitDays,
    this.colorHex,
    required this.isArchived,
  });

  final String id;
  final String name;
  final double annualAllowanceDays;
  final double? carryForwardLimitDays;
  final String? colorHex;
  final bool isArchived;
}
