/// Values of an [AttendanceDay]'s `status`, matching the backend.
class AttendanceStatus {
  static const present = 'present';
  static const late = 'late';
  static const incomplete = 'incomplete';
  static const absent = 'absent';
  static const leave = 'leave';
  static const holiday = 'holiday';
  static const weekend = 'weekend';
  static const pending = 'pending';
  static const upcoming = 'upcoming';
}

class AttendanceDay {
  const AttendanceDay({
    required this.date,
    required this.weekday,
    required this.clockIn,
    required this.clockOut,
    required this.lateMinutes,
    required this.earlyMinutes,
    required this.workMinutes,
    required this.status,
  });

  /// yyyy-MM-dd
  final String date;
  final String weekday;

  /// "HH:mm", Pakistan time.
  final String? clockIn;
  final String? clockOut;
  final int lateMinutes;
  final int earlyMinutes;
  final int workMinutes;
  final String status;
}

class AttendanceSummary {
  const AttendanceSummary({
    required this.present,
    required this.late,
    required this.absent,
    required this.leave,
    required this.incomplete,
    required this.lateMinutes,
    required this.workMinutes,
  });

  final int present;
  final int late;
  final int absent;
  final int leave;
  final int incomplete;
  final int lateMinutes;
  final int workMinutes;
}

class EmployeeAttendance {
  const EmployeeAttendance({
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.profilePhotoUrl,
    required this.linked,
    required this.days,
    required this.summary,
    this.remote = false,
  });

  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String? profilePhotoUrl;

  /// False when the employee isn't linked to a machine user yet.
  final bool linked;

  /// Remote staff aren't tracked on the machine.
  final bool remote;
  final List<AttendanceDay> days;
  final AttendanceSummary summary;
}

class AttendanceSettings {
  const AttendanceSettings({
    required this.shiftStart,
    required this.shiftEnd,
    required this.graceMinutes,
    required this.lastSyncAt,
    required this.lastSyncMessage,
    required this.deviceConfigured,
  });

  final String shiftStart;
  final String shiftEnd;
  final int graceMinutes;
  final DateTime? lastSyncAt;
  final String? lastSyncMessage;
  final bool deviceConfigured;
}

/// One person enrolled on the machine and who (if anyone) they're linked to.
class AttendanceMapping {
  const AttendanceMapping({
    required this.deviceUserId,
    required this.deviceName,
    required this.employeeId,
    required this.employeeName,
    this.ignored = false,
  });

  final String deviceUserId;
  final String deviceName;
  final String? employeeId;
  final String? employeeName;

  /// Still enrolled on the machine but no longer works here.
  final bool ignored;
}

class AttendanceSyncResult {
  const AttendanceSyncResult({
    required this.fetched,
    required this.inserted,
    required this.users,
  });

  final int fetched;
  final int inserted;
  final int users;
}

/// "HH:mm" for a number of minutes, or '' for zero — the report leaves empty
/// cells rather than printing 00:00 everywhere.
String formatAttendanceMinutes(int minutes, {bool blankZero = true}) {
  if (minutes <= 0 && blankZero) return '';
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}
