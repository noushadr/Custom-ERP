import '../../domain/entities/attendance.dart';

AttendanceDay attendanceDayFromJson(Map<String, dynamic> json) => AttendanceDay(
  date: json['date'] as String,
  weekday: json['weekday'] as String,
  clockIn: json['clockIn'] as String?,
  clockOut: json['clockOut'] as String?,
  lateMinutes: json['lateMinutes'] as int,
  earlyMinutes: json['earlyMinutes'] as int,
  workMinutes: json['workMinutes'] as int,
  status: json['status'] as String,
  hoursCutMinutes: json['hoursCutMinutes'] as int? ?? 0,
  arrivalLateMinutes: json['arrivalLateMinutes'] as int? ?? 0,
  extraMinutes: json['extraMinutes'] as int? ?? 0,
  leaveType: json['leaveType'] as String?,
);

AttendanceSummary attendanceSummaryFromJson(Map<String, dynamic> json) =>
    AttendanceSummary(
      present: json['present'] as int,
      late: json['late'] as int,
      lateDeductionDays: json['lateDeductionDays'] as int? ?? 0,
      absent: json['absent'] as int,
      leave: json['leave'] as int,
      incomplete: json['incomplete'] as int,
      wfhDays: json['wfhDays'] as int? ?? 0,
      hoursCutDays: json['hoursCutDays'] as int? ?? 0,
      hoursCutMinutes: json['hoursCutMinutes'] as int? ?? 0,
      lateMinutes: json['lateMinutes'] as int,
      workMinutes: json['workMinutes'] as int,
    );

EmployeeAttendance employeeAttendanceFromJson(Map<String, dynamic> json) =>
    EmployeeAttendance(
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String,
      employeeCode: json['employeeCode'] as String,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      linked: json['linked'] as bool,
      remote: json['remote'] as bool? ?? false,
      days: (json['days'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(attendanceDayFromJson)
          .toList(),
      summary: attendanceSummaryFromJson(
        json['summary'] as Map<String, dynamic>,
      ),
    );

AttendanceSettings attendanceSettingsFromJson(Map<String, dynamic> json) =>
    AttendanceSettings(
      shiftStart: json['shiftStart'] as String,
      shiftEnd: json['shiftEnd'] as String,
      hoursCutAfter: json['hoursCutAfter'] as String? ?? '11:30',
      hoursCutFrom: json['hoursCutFrom'] as String? ?? '10:30',
      graceMinutes: json['graceMinutes'] as int,
      lastSyncAt: json['lastSyncAt'] == null
          ? null
          : DateTime.parse(json['lastSyncAt'] as String).toLocal(),
      lastSyncMessage: json['lastSyncMessage'] as String?,
      deviceConfigured: json['deviceConfigured'] as bool,
    );

WfhDay wfhDayFromJson(Map<String, dynamic> json) => WfhDay(
  date: json['date'] as String,
  note: json['note'] as String?,
  presentCount: json['presentCount'] as int,
);

WfhDayEmployee wfhDayEmployeeFromJson(Map<String, dynamic> json) =>
    WfhDayEmployee(
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String,
      employeeCode: json['employeeCode'] as String,
      present: json['present'] as bool,
    );

AttendanceMapping attendanceMappingFromJson(Map<String, dynamic> json) =>
    AttendanceMapping(
      deviceUserId: json['deviceUserId'] as String,
      deviceName: json['deviceName'] as String,
      employeeId: json['employeeId'] as String?,
      employeeName: json['employeeName'] as String?,
      ignored: json['ignored'] as bool? ?? false,
    );
