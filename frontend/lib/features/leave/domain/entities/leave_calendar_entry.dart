class LeaveCalendarEntry {
  const LeaveCalendarEntry({
    required this.employeeId,
    required this.employeeName,
    this.employeePhotoUrl,
    required this.leaveTypeId,
    required this.leaveTypeName,
    this.colorHex,
    required this.startDate,
    required this.endDate,
    required this.isPending,
  });

  final String employeeId;
  final String employeeName;
  final String? employeePhotoUrl;
  final String leaveTypeId;
  final String leaveTypeName;
  final String? colorHex;
  final String startDate;
  final String endDate;

  /// True while only the manager (not HR/Admin) has approved yet.
  final bool isPending;
}
