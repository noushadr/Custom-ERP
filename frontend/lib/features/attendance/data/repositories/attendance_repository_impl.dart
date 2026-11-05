import 'package:dio/dio.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/exceptions/attendance_exception.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_data_source.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  const AttendanceRepositoryImpl(this._remote);

  final AttendanceRemoteDataSource _remote;

  @override
  Future<EmployeeAttendance> getMine({required int month, required int year}) =>
      _guard(() => _remote.getMine(month: month, year: year));

  @override
  Future<List<EmployeeAttendance>> getCompany({
    required int month,
    required int year,
  }) => _guard(() => _remote.getCompany(month: month, year: year));

  @override
  Future<EmployeeAttendance> getEmployee(
    String employeeId, {
    required int month,
    required int year,
  }) => _guard(() => _remote.getEmployee(employeeId, month: month, year: year));

  @override
  Future<List<int>> downloadPdf({
    required int month,
    required int year,
    String? employeeId,
  }) => _guard(
    () => _remote.downloadPdf(month: month, year: year, employeeId: employeeId),
  );

  @override
  Future<AttendanceSettings> getSettings() =>
      _guard(() => _remote.getSettings());

  @override
  Future<AttendanceSettings> updateSettings({
    required String shiftStart,
    required String shiftEnd,
    required String hoursCutAfter,
    required String hoursCutFrom,
    required int graceMinutes,
  }) => _guard(
    () => _remote.updateSettings(
      shiftStart: shiftStart,
      shiftEnd: shiftEnd,
      hoursCutAfter: hoursCutAfter,
      hoursCutFrom: hoursCutFrom,
      graceMinutes: graceMinutes,
    ),
  );

  @override
  Future<AttendanceSyncResult> sync() => _guard(() => _remote.sync());

  @override
  Future<AttendanceSyncResult> refresh() => _guard(() => _remote.refresh());

  @override
  Future<List<AttendanceMapping>> getMapping() =>
      _guard(() => _remote.getMapping());

  @override
  Future<List<AttendanceMapping>> setMapping({
    required String employeeId,
    String? deviceUserId,
  }) => _guard(
    () =>
        _remote.setMapping(employeeId: employeeId, deviceUserId: deviceUserId),
  );

  @override
  Future<List<AttendanceMapping>> setIgnored({
    required String deviceUserId,
    required bool ignored,
  }) => _guard(
    () => _remote.setIgnored(deviceUserId: deviceUserId, ignored: ignored),
  );

  @override
  Future<List<({String date, String? note})>> getWfhCalendar() =>
      _guard(() => _remote.getWfhCalendar());

  @override
  Future<List<WfhDay>> getWfhDays() => _guard(() => _remote.getWfhDays());

  @override
  Future<WfhDay> addWfhDay({required String date, String? note}) =>
      _guard(() => _remote.addWfhDay(date: date, note: note));

  @override
  Future<void> removeWfhDay(String date) =>
      _guard(() => _remote.removeWfhDay(date));

  @override
  Future<List<WfhDayEmployee>> getWfhDayAttendance(String date) =>
      _guard(() => _remote.getWfhDayAttendance(date));

  @override
  Future<List<WfhDayEmployee>> setWfhDayAttendance({
    required String date,
    required List<String> employeeIds,
  }) => _guard(
    () => _remote.setWfhDayAttendance(date: date, employeeIds: employeeIds),
  );

  @override
  Future<void> markEmployeeWfh({
    required String employeeId,
    required String date,
  }) =>
      _guard(() => _remote.markEmployeeWfh(employeeId: employeeId, date: date));

  @override
  Future<void> unmarkEmployeeWfh({
    required String employeeId,
    required String date,
  }) => _guard(
    () => _remote.unmarkEmployeeWfh(employeeId: employeeId, date: date),
  );

  @override
  Future<int> autoMap() => _guard(() => _remote.autoMap());

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw AttendanceException(_mapError(error));
    }
  }

  String _mapError(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    if ((status == 400 || status == 409) &&
        data is Map &&
        data['message'] is String) {
      return data['message'] as String;
    }
    if (status == 400 && data is Map && data['message'] is List) {
      return (data['message'] as List).join(', ');
    }
    if (status == 403) return "You don't have permission to do that.";
    if (status == 404) return 'No attendance record for this profile.';
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
