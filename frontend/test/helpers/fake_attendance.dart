import 'package:zera_erp/features/attendance/domain/entities/attendance.dart';
import 'package:zera_erp/features/attendance/domain/exceptions/attendance_exception.dart';
import 'package:zera_erp/features/attendance/domain/repositories/attendance_repository.dart';

AttendanceDay buildTestAttendanceDay({
  String date = '2026-10-05',
  String weekday = 'Mon',
  String? clockIn = '10:42',
  String? clockOut = '18:26',
  int lateMinutes = 0,
  int earlyMinutes = 34,
  int workMinutes = 464,
  String status = AttendanceStatus.present,
  String? leaveType,
  int arrivalLateMinutes = 0,
  int extraMinutes = 0,
}) => AttendanceDay(
  date: date,
  weekday: weekday,
  clockIn: clockIn,
  clockOut: clockOut,
  lateMinutes: lateMinutes,
  earlyMinutes: earlyMinutes,
  workMinutes: workMinutes,
  status: status,
  leaveType: leaveType,
  arrivalLateMinutes: arrivalLateMinutes,
  extraMinutes: extraMinutes,
);

EmployeeAttendance buildTestEmployeeAttendance({
  String employeeId = 'employee-1',
  String employeeName = 'Jane Doe',
  String employeeCode = 'ZC-00001',
  bool linked = true,
  bool remote = false,
  List<AttendanceDay>? days,
  AttendanceSummary? summary,
}) => EmployeeAttendance(
  employeeId: employeeId,
  employeeName: employeeName,
  employeeCode: employeeCode,
  profilePhotoUrl: null,
  linked: linked,
  remote: remote,
  days: linked ? (days ?? [buildTestAttendanceDay()]) : const [],
  summary:
      summary ??
      const AttendanceSummary(
        present: 1,
        late: 0,
        absent: 0,
        leave: 0,
        incomplete: 0,
        lateMinutes: 0,
        workMinutes: 464,
      ),
);

class FakeAttendanceRepository implements AttendanceRepository {
  FakeAttendanceRepository({
    EmployeeAttendance? mine,
    this.company = const [],
    this.mapping = const [],
    this.mineError,
    this.deviceConfigured = true,
    this.wfhDays = const [],
    this.wfhEmployees = const [],
  }) : mine = mine ?? buildTestEmployeeAttendance();

  final EmployeeAttendance mine;
  final List<EmployeeAttendance> company;
  List<AttendanceMapping> mapping;
  final AttendanceException? mineError;
  final bool deviceConfigured;
  final List<WfhDay> wfhDays;
  final List<WfhDayEmployee> wfhEmployees;

  int syncCalls = 0;
  int autoMapCalls = 0;
  String? lastPdfEmployeeId;
  int pdfCalls = 0;
  String? lastLinkedEmployeeId;
  String? lastLinkedDeviceUserId;
  AttendanceSettings? savedSettings;

  @override
  Future<EmployeeAttendance> getMine({
    required int month,
    required int year,
  }) async {
    if (mineError != null) throw mineError!;
    return mine;
  }

  @override
  Future<List<EmployeeAttendance>> getCompany({
    required int month,
    required int year,
  }) async => company;

  @override
  Future<EmployeeAttendance> getEmployee(
    String employeeId, {
    required int month,
    required int year,
  }) async => company.firstWhere((e) => e.employeeId == employeeId);

  @override
  Future<List<int>> downloadPdf({
    required int month,
    required int year,
    String? employeeId,
  }) async {
    pdfCalls++;
    lastPdfEmployeeId = employeeId;
    return [37, 80, 68, 70];
  }

  @override
  Future<AttendanceSettings> getSettings() async =>
      savedSettings ??
      AttendanceSettings(
        shiftStart: '11:00',
        shiftEnd: '19:00',
        hoursCutAfter: '11:30',
        hoursCutFrom: '10:30',
        graceMinutes: 15,
        lastSyncAt: null,
        lastSyncMessage: null,
        deviceConfigured: deviceConfigured,
      );

  @override
  Future<AttendanceSettings> updateSettings({
    required String shiftStart,
    required String shiftEnd,
    required String hoursCutAfter,
    required String hoursCutFrom,
    required int graceMinutes,
  }) async {
    savedSettings = AttendanceSettings(
      shiftStart: shiftStart,
      shiftEnd: shiftEnd,
      hoursCutAfter: hoursCutAfter,
      hoursCutFrom: hoursCutFrom,
      graceMinutes: graceMinutes,
      lastSyncAt: null,
      lastSyncMessage: null,
      deviceConfigured: deviceConfigured,
    );
    return savedSettings!;
  }

  @override
  Future<AttendanceSyncResult> sync() async {
    syncCalls++;
    return const AttendanceSyncResult(fetched: 10, inserted: 3, users: 2);
  }

  String? lastAddedWfhDate;
  String? lastAddedWfhNote;
  String? lastRemovedWfhDate;
  String? lastMarkedWfhDate;
  List<String>? lastMarkedWfhEmployeeIds;

  @override
  Future<List<({String date, String? note})>> getWfhCalendar() async => [
    for (final d in wfhDays) (date: d.date, note: d.note),
  ];

  @override
  Future<List<WfhDay>> getWfhDays() async => wfhDays;

  @override
  Future<WfhDay> addWfhDay({required String date, String? note}) async {
    lastAddedWfhDate = date;
    lastAddedWfhNote = note;
    return WfhDay(date: date, note: note, presentCount: 0);
  }

  @override
  Future<void> removeWfhDay(String date) async {
    lastRemovedWfhDate = date;
  }

  @override
  Future<List<WfhDayEmployee>> getWfhDayAttendance(String date) async =>
      wfhEmployees;

  @override
  Future<List<WfhDayEmployee>> setWfhDayAttendance({
    required String date,
    required List<String> employeeIds,
  }) async {
    lastMarkedWfhDate = date;
    lastMarkedWfhEmployeeIds = employeeIds;
    return wfhEmployees;
  }

  String? lastMarkedWfhEmployeeId;
  String? lastMarkedWfhEmployeeDate;
  String? lastUnmarkedWfhEmployeeDate;

  @override
  Future<void> markEmployeeWfh({
    required String employeeId,
    required String date,
  }) async {
    lastMarkedWfhEmployeeId = employeeId;
    lastMarkedWfhEmployeeDate = date;
  }

  @override
  Future<void> unmarkEmployeeWfh({
    required String employeeId,
    required String date,
  }) async {
    lastUnmarkedWfhEmployeeDate = date;
  }

  int refreshCalls = 0;

  @override
  Future<AttendanceSyncResult> refresh() async {
    refreshCalls++;
    return const AttendanceSyncResult(fetched: 10, inserted: 2, users: 2);
  }

  @override
  Future<List<AttendanceMapping>> getMapping() async => mapping;

  @override
  Future<List<AttendanceMapping>> setMapping({
    required String employeeId,
    String? deviceUserId,
  }) async {
    lastLinkedEmployeeId = employeeId;
    lastLinkedDeviceUserId = deviceUserId;
    return mapping;
  }

  String? lastIgnoredDeviceUserId;
  bool? lastIgnoredValue;

  @override
  Future<List<AttendanceMapping>> setIgnored({
    required String deviceUserId,
    required bool ignored,
  }) async {
    lastIgnoredDeviceUserId = deviceUserId;
    lastIgnoredValue = ignored;
    return mapping;
  }

  @override
  Future<int> autoMap() async {
    autoMapCalls++;
    return 4;
  }
}
