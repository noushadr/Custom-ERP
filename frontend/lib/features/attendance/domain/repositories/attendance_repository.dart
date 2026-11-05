import '../entities/attendance.dart';

abstract class AttendanceRepository {
  /// The signed-in employee's own month.
  Future<EmployeeAttendance> getMine({required int month, required int year});

  /// Every active employee's month. Requires `attendance.manage`.
  Future<List<EmployeeAttendance>> getCompany({
    required int month,
    required int year,
  });

  /// One employee's month. Requires `attendance.manage`.
  Future<EmployeeAttendance> getEmployee(
    String employeeId, {
    required int month,
    required int year,
  });

  /// A PDF of the month: [employeeId]'s, or (HR/Admin, no id) everyone's.
  Future<List<int>> downloadPdf({
    required int month,
    required int year,
    String? employeeId,
  });

  Future<AttendanceSettings> getSettings();

  Future<AttendanceSettings> updateSettings({
    required String shiftStart,
    required String shiftEnd,
    required String hoursCutAfter,
    required String hoursCutFrom,
    required int graceMinutes,
  });

  Future<AttendanceSyncResult> sync();

  /// Any signed-in user: pulls the latest scans unless a sync just ran.
  Future<AttendanceSyncResult> refresh();

  Future<List<AttendanceMapping>> getMapping();

  /// Links (or, with a null [deviceUserId], unlinks) an employee.
  Future<List<AttendanceMapping>> setMapping({
    required String employeeId,
    String? deviceUserId,
  });

  /// Marks a machine user as no longer working here (or restores them).
  Future<List<AttendanceMapping>> setIgnored({
    required String deviceUserId,
    required bool ignored,
  });

  /// Every company work-from-home day (date + note only), for the calendar.
  Future<List<({String date, String? note})>> getWfhCalendar();

  /// Work-from-home days from two months back onward. HR/Admin only.
  Future<List<WfhDay>> getWfhDays();

  Future<WfhDay> addWfhDay({required String date, String? note});

  Future<void> removeWfhDay(String date);

  /// The tracked employees and whether each was marked as having worked.
  Future<List<WfhDayEmployee>> getWfhDayAttendance(String date);

  /// Replaces who is marked as having worked on that work-from-home day.
  Future<List<WfhDayEmployee>> setWfhDayAttendance({
    required String date,
    required List<String> employeeIds,
  });

  /// HR marks one person's own day as work from home (a genuine issue): no
  /// machine attendance that day, just present.
  Future<void> markEmployeeWfh({
    required String employeeId,
    required String date,
  });

  Future<void> unmarkEmployeeWfh({
    required String employeeId,
    required String date,
  });

  /// Links machine users to employees with matching names. Returns how many.
  Future<int> autoMap();
}
