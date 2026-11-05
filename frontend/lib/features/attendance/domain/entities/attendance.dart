/// Values of an [AttendanceDay]'s `status`, matching the backend.
class AttendanceStatus {
  static const present = 'present';
  static const late = 'late';
  static const incomplete = 'incomplete';
  static const missingCheckin = 'missing_checkin';
  static const hoursCut = 'hours_cut';
  static const wfh = 'wfh';
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
    this.hoursCutMinutes = 0,
    this.arrivalLateMinutes = 0,
    this.extraMinutes = 0,
    this.leaveType,
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

  /// On an Hours Cut day: the time between the shift start and arriving.
  final int hoursCutMinutes;

  /// How long after the shift start they arrived (late and hours-cut days).
  final int arrivalLateMinutes;

  /// Minutes stayed past the shift end.
  final int extraMinutes;

  /// Which kind of leave (Casual, Sick, Annual...) on a leave day.
  final String? leaveType;
}

class AttendanceSummary {
  const AttendanceSummary({
    required this.present,
    required this.late,
    this.lateDeductionDays = 0,
    required this.absent,
    required this.leave,
    required this.incomplete,
    this.wfhDays = 0,
    this.hoursCutDays = 0,
    this.hoursCutMinutes = 0,
    required this.lateMinutes,
    required this.workMinutes,
  });

  final int present;
  final int late;

  /// Unpaid absences earned by lates: one per third late day in the month.
  final int lateDeductionDays;
  final int absent;
  final int leave;
  final int incomplete;

  /// Work-from-home days HR marked as worked.
  final int wfhDays;

  /// Days arriving after the cut-off, and the hours cut across them.
  final int hoursCutDays;
  final int hoursCutMinutes;
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
    required this.hoursCutAfter,
    required this.hoursCutFrom,
    required this.graceMinutes,
    required this.lastSyncAt,
    required this.lastSyncMessage,
    required this.deviceConfigured,
  });

  final String shiftStart;
  final String shiftEnd;

  /// Arriving after this is an Hours Cut day rather than a late mark.
  final String hoursCutAfter;

  /// Whole hours are counted from this time on an Hours Cut day.
  final String hoursCutFrom;
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

/// A company-wide work-from-home day: no machine attendance, HR marks who
/// worked.
class WfhDay {
  const WfhDay({
    required this.date,
    required this.note,
    required this.presentCount,
  });

  /// yyyy-MM-dd
  final String date;
  final String? note;
  final int presentCount;
}

/// One tracked employee on a work-from-home day, and whether HR marked them
/// as having worked.
class WfhDayEmployee {
  const WfhDayEmployee({
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.present,
  });

  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final bool present;
}

class AttendanceSyncResult {
  const AttendanceSyncResult({
    required this.fetched,
    required this.inserted,
    required this.users,
    this.skipped = false,
  });

  final int fetched;
  final int inserted;
  final int users;

  /// A recent sync already covered it, so the machine wasn't asked again.
  final bool skipped;
}

/// A length of time in words: "7hr 30m", "8hr" or "45m". Zero is empty
/// (the report leaves blank cells) or, with [blankZero] false, "0".
String formatAttendanceMinutes(int minutes, {bool blankZero = true}) {
  if (minutes <= 0) return blankZero ? '' : '0';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  return m == 0 ? '${h}hr' : '${h}hr ${m}m';
}
