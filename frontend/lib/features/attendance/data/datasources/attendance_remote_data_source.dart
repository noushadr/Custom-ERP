import 'package:dio/dio.dart';
import '../../domain/entities/attendance.dart';
import '../models/attendance_models.dart';

class AttendanceRemoteDataSource {
  const AttendanceRemoteDataSource(this._dio);

  final Dio _dio;

  Map<String, String> _period(int month, int year) => {
    'month': month.toString(),
    'year': year.toString(),
  };

  Future<EmployeeAttendance> getMine({
    required int month,
    required int year,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/attendance/me',
      queryParameters: _period(month, year),
    );
    return employeeAttendanceFromJson(response.data!);
  }

  Future<List<EmployeeAttendance>> getCompany({
    required int month,
    required int year,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/attendance/report',
      queryParameters: _period(month, year),
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(employeeAttendanceFromJson)
        .toList();
  }

  Future<EmployeeAttendance> getEmployee(
    String employeeId, {
    required int month,
    required int year,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/attendance/employees/$employeeId',
      queryParameters: _period(month, year),
    );
    return employeeAttendanceFromJson(response.data!);
  }

  Future<List<int>> downloadPdf({
    required int month,
    required int year,
    String? employeeId,
  }) async {
    final response = await _dio.get<List<int>>(
      '/attendance/pdf',
      queryParameters: {..._period(month, year), 'employeeId': ?employeeId},
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data!;
  }

  Future<AttendanceSettings> getSettings() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/attendance/settings',
    );
    return attendanceSettingsFromJson(response.data!);
  }

  Future<AttendanceSettings> updateSettings({
    required String shiftStart,
    required String shiftEnd,
    required String hoursCutAfter,
    required String hoursCutFrom,
    required int graceMinutes,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/attendance/settings',
      data: {
        'shiftStart': shiftStart,
        'shiftEnd': shiftEnd,
        'hoursCutAfter': hoursCutAfter,
        'hoursCutFrom': hoursCutFrom,
        'graceMinutes': graceMinutes,
      },
    );
    return attendanceSettingsFromJson(response.data!);
  }

  Future<AttendanceSyncResult> sync() => _post('/attendance/sync');

  Future<AttendanceSyncResult> refresh() => _post('/attendance/refresh');

  Future<AttendanceSyncResult> _post(String path) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    );
    final data = response.data!;
    return AttendanceSyncResult(
      fetched: data['fetched'] as int,
      inserted: data['inserted'] as int,
      users: data['users'] as int,
      skipped: data['skipped'] as bool? ?? false,
    );
  }

  Future<List<AttendanceMapping>> getMapping() async {
    final response = await _dio.get<List<dynamic>>('/attendance/mapping');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(attendanceMappingFromJson)
        .toList();
  }

  Future<List<AttendanceMapping>> setMapping({
    required String employeeId,
    String? deviceUserId,
  }) async {
    final response = await _dio.put<List<dynamic>>(
      '/attendance/mapping',
      data: {'employeeId': employeeId, 'deviceUserId': deviceUserId},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(attendanceMappingFromJson)
        .toList();
  }

  Future<List<AttendanceMapping>> setIgnored({
    required String deviceUserId,
    required bool ignored,
  }) async {
    final response = await _dio.put<List<dynamic>>(
      '/attendance/mapping/ignore',
      data: {'deviceUserId': deviceUserId, 'ignored': ignored},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(attendanceMappingFromJson)
        .toList();
  }

  Future<List<({String date, String? note})>> getWfhCalendar() async {
    final response = await _dio.get<List<dynamic>>('/attendance/wfh-calendar');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map((j) => (date: j['date'] as String, note: j['note'] as String?))
        .toList();
  }

  Future<List<WfhDay>> getWfhDays() async {
    final response = await _dio.get<List<dynamic>>('/attendance/wfh-days');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(wfhDayFromJson)
        .toList();
  }

  Future<WfhDay> addWfhDay({required String date, String? note}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/attendance/wfh-days',
      data: {'date': date, 'note': ?note},
    );
    return wfhDayFromJson(response.data!);
  }

  Future<void> removeWfhDay(String date) async {
    await _dio.delete<void>('/attendance/wfh-days/$date');
  }

  Future<List<WfhDayEmployee>> getWfhDayAttendance(String date) async {
    final response = await _dio.get<List<dynamic>>(
      '/attendance/wfh-days/$date/attendance',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(wfhDayEmployeeFromJson)
        .toList();
  }

  Future<List<WfhDayEmployee>> setWfhDayAttendance({
    required String date,
    required List<String> employeeIds,
  }) async {
    final response = await _dio.put<List<dynamic>>(
      '/attendance/wfh-days/$date/attendance',
      data: {'employeeIds': employeeIds},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(wfhDayEmployeeFromJson)
        .toList();
  }

  Future<void> markEmployeeWfh({
    required String employeeId,
    required String date,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/attendance/employees/$employeeId/wfh-days',
      data: {'date': date},
    );
  }

  Future<void> unmarkEmployeeWfh({
    required String employeeId,
    required String date,
  }) async {
    await _dio.delete<void>('/attendance/employees/$employeeId/wfh-days/$date');
  }

  Future<int> autoMap() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/attendance/mapping/auto',
    );
    return response.data!['linked'] as int;
  }
}
