class LeaveBalance {
  const LeaveBalance({
    required this.leaveTypeId,
    required this.leaveTypeName,
    this.colorHex,
    required this.year,
    required this.allocated,
    required this.used,
    required this.remaining,
  });

  final String leaveTypeId;
  final String leaveTypeName;
  final String? colorHex;
  final int year;
  final double allocated;
  final double used;
  final double remaining;
}
