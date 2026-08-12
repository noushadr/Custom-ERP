import '../../domain/entities/leave_calendar_entry.dart';

class LeaveCalendarEntryModel extends LeaveCalendarEntry {
  const LeaveCalendarEntryModel({
    required super.employeeId,
    required super.employeeName,
    super.employeePhotoUrl,
    required super.leaveTypeId,
    required super.leaveTypeName,
    super.colorHex,
    required super.startDate,
    required super.endDate,
    required super.isPending,
  });

  factory LeaveCalendarEntryModel.fromJson(Map<String, dynamic> json) =>
      LeaveCalendarEntryModel(
        employeeId: json['employeeId'] as String,
        employeeName: json['employeeName'] as String,
        employeePhotoUrl: json['employeePhotoUrl'] as String?,
        leaveTypeId: json['leaveTypeId'] as String,
        leaveTypeName: json['leaveTypeName'] as String,
        colorHex: json['colorHex'] as String?,
        startDate: json['startDate'] as String,
        endDate: json['endDate'] as String,
        isPending: json['isPending'] as bool,
      );
}
