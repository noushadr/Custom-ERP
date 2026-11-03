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
    required int graceMinutes,
  });

  Future<AttendanceSyncResult> sync();

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

  /// Links machine users to employees with matching names. Returns how many.
  Future<int> autoMap();
}
