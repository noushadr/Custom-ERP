import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/employee_remote_data_source.dart';
import '../data/repositories/employee_repository_impl.dart';
import '../domain/entities/asset.dart';
import '../domain/entities/audit_log_entry.dart';
import '../domain/entities/department.dart';
import '../domain/entities/education_record.dart';
import '../domain/entities/employee.dart';
import '../domain/entities/employee_document.dart';
import '../domain/entities/paginated_audit_log.dart';
import '../domain/entities/salary_record.dart';
import '../domain/entities/upcoming_birthday.dart';
import '../domain/repositories/employee_repository.dart';

final employeeRemoteDataSourceProvider = Provider<EmployeeRemoteDataSource>(
  (ref) => EmployeeRemoteDataSource(ref.watch(dioClientProvider).dio),
);

final employeeRepositoryProvider = Provider<EmployeeRepository>(
  (ref) => EmployeeRepositoryImpl(ref.watch(employeeRemoteDataSourceProvider)),
);

// Every provider below re-watches authControllerProvider purely to create a
// dependency edge: none of these auto-invalidate on their own when identity
// changes (impersonate/returnToAdmin/logout), since the underlying Dio client
// reads the current token per-request rather than being reconstructed. If
// this were skipped, one identity's fetched-and-cached data (or NotFound
// error) would silently keep showing after switching to another, since
// nothing else in the dependency graph would prompt Riverpod to refetch.

final employeeListProvider = FutureProvider.autoDispose<List<Employee>>((
  ref,
) {
  ref.watch(authControllerProvider);
  return ref.watch(employeeRepositoryProvider).getAll();
});

final myProfileProvider = FutureProvider.autoDispose<Employee>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(employeeRepositoryProvider).getMe();
});

final upcomingBirthdaysProvider =
    FutureProvider.autoDispose<List<UpcomingBirthday>>((ref) {
      ref.watch(authControllerProvider);
      return ref.watch(employeeRepositoryProvider).getUpcomingBirthdays();
    });

final myDirectReportsProvider = FutureProvider.autoDispose<List<Employee>>((
  ref,
) {
  ref.watch(authControllerProvider);
  return ref.watch(employeeRepositoryProvider).getMyDirectReports();
});

final employeeDetailProvider = FutureProvider.autoDispose
    .family<Employee, String>((ref, id) {
      ref.watch(authControllerProvider);
      return ref.watch(employeeRepositoryProvider).getById(id);
    });

final departmentsProvider = FutureProvider.autoDispose<List<Department>>((
  ref,
) {
  ref.watch(authControllerProvider);
  return ref.watch(employeeRepositoryProvider).getDepartments();
});

/// Keyed by whether archived departments should be included — used by the
/// departments management screen, which lets the viewer toggle that. Plain
/// pickers elsewhere use [departmentsProvider] instead, which always
/// excludes archived departments.
final departmentsManagementProvider = FutureProvider.autoDispose
    .family<List<Department>, bool>((ref, includeArchived) {
      ref.watch(authControllerProvider);
      return ref
          .watch(employeeRepositoryProvider)
          .getDepartments(includeArchived: includeArchived);
    });

final myDocumentsProvider = FutureProvider.autoDispose<List<EmployeeDocument>>(
  (ref) {
    ref.watch(authControllerProvider);
    return ref.watch(employeeRepositoryProvider).getMyDocuments();
  },
);

final employeeDocumentsProvider = FutureProvider.autoDispose
    .family<List<EmployeeDocument>, String>((ref, employeeId) {
      ref.watch(authControllerProvider);
      return ref.watch(employeeRepositoryProvider).getDocuments(employeeId);
    });

final myAuditLogProvider = FutureProvider.autoDispose<List<AuditLogEntry>>((
  ref,
) {
  ref.watch(authControllerProvider);
  return ref.watch(employeeRepositoryProvider).getMyAuditLog();
});

final employeeAuditLogProvider = FutureProvider.autoDispose
    .family<List<AuditLogEntry>, String>((ref, employeeId) {
      ref.watch(authControllerProvider);
      return ref.watch(employeeRepositoryProvider).getAuditLog(employeeId);
    });

class CompanyAuditLogQuery {
  const CompanyAuditLogQuery({
    required this.page,
    required this.limit,
    this.search,
  });

  final int page;
  final int limit;
  final String? search;

  @override
  bool operator ==(Object other) =>
      other is CompanyAuditLogQuery &&
      other.page == page &&
      other.limit == limit &&
      other.search == search;

  @override
  int get hashCode => Object.hash(page, limit, search);
}

final companyAuditLogProvider = FutureProvider.autoDispose
    .family<PaginatedAuditLog, CompanyAuditLogQuery>((ref, query) {
      ref.watch(authControllerProvider);
      return ref
          .watch(employeeRepositoryProvider)
          .getCompanyAuditLog(
            page: query.page,
            limit: query.limit,
            search: query.search,
          );
    });

final mySalaryHistoryProvider = FutureProvider.autoDispose<List<SalaryRecord>>(
  (ref) {
    ref.watch(authControllerProvider);
    return ref.watch(employeeRepositoryProvider).getMySalaryHistory();
  },
);

final employeeSalaryHistoryProvider = FutureProvider.autoDispose
    .family<List<SalaryRecord>, String>((ref, employeeId) {
      ref.watch(authControllerProvider);
      return ref
          .watch(employeeRepositoryProvider)
          .getSalaryHistory(employeeId);
    });

final myAssetsProvider = FutureProvider.autoDispose<List<Asset>>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(employeeRepositoryProvider).getMyAssets();
});

final employeeAssetsProvider = FutureProvider.autoDispose
    .family<List<Asset>, String>((ref, employeeId) {
      ref.watch(authControllerProvider);
      return ref.watch(employeeRepositoryProvider).getAssets(employeeId);
    });

final myEducationHistoryProvider =
    FutureProvider.autoDispose<List<EducationRecord>>((ref) {
      ref.watch(authControllerProvider);
      return ref.watch(employeeRepositoryProvider).getMyEducationHistory();
    });

final employeeEducationHistoryProvider = FutureProvider.autoDispose
    .family<List<EducationRecord>, String>((ref, employeeId) {
      ref.watch(authControllerProvider);
      return ref
          .watch(employeeRepositoryProvider)
          .getEducationHistory(employeeId);
    });
