import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/file_download/file_download.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/attendance_remote_data_source.dart';
import '../data/repositories/attendance_repository_impl.dart';
import '../domain/entities/attendance.dart';
import '../domain/repositories/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepositoryImpl(
    AttendanceRemoteDataSource(ref.watch(dioClientProvider).dio),
  ),
);

/// Saves an exported PDF to the user's device — a provider so widget tests
/// (which have no browser to download into) can observe it instead.
final attendancePdfSaverProvider =
    Provider<void Function(List<int> bytes, String fileName)>(
      (ref) =>
          (bytes, fileName) =>
              downloadBytes(bytes, fileName, mimeType: 'application/pdf'),
    );

typedef AttendancePeriod = ({int month, int year});

// Every provider below re-watches authControllerProvider purely to create a
// dependency edge, so switching identity triggers a refetch — see the longer
// explanation in employee_providers.dart.

final myAttendanceProvider = FutureProvider.autoDispose
    .family<EmployeeAttendance, AttendancePeriod>((ref, period) {
      ref.watch(authControllerProvider);
      return ref
          .watch(attendanceRepositoryProvider)
          .getMine(month: period.month, year: period.year);
    });

final companyAttendanceProvider = FutureProvider.autoDispose
    .family<List<EmployeeAttendance>, AttendancePeriod>((ref, period) {
      ref.watch(authControllerProvider);
      return ref
          .watch(attendanceRepositoryProvider)
          .getCompany(month: period.month, year: period.year);
    });

final attendanceSettingsProvider =
    FutureProvider.autoDispose<AttendanceSettings>((ref) {
      ref.watch(authControllerProvider);
      return ref.watch(attendanceRepositoryProvider).getSettings();
    });

final wfhCalendarProvider =
    FutureProvider.autoDispose<List<({String date, String? note})>>((ref) {
      ref.watch(authControllerProvider);
      return ref.watch(attendanceRepositoryProvider).getWfhCalendar();
    });

final wfhDaysProvider = FutureProvider.autoDispose<List<WfhDay>>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(attendanceRepositoryProvider).getWfhDays();
});

final wfhDayAttendanceProvider = FutureProvider.autoDispose
    .family<List<WfhDayEmployee>, String>((ref, date) {
      ref.watch(authControllerProvider);
      return ref.watch(attendanceRepositoryProvider).getWfhDayAttendance(date);
    });

final attendanceMappingProvider =
    FutureProvider.autoDispose<List<AttendanceMapping>>((ref) {
      ref.watch(authControllerProvider);
      return ref.watch(attendanceRepositoryProvider).getMapping();
    });
