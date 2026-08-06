import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/named_ref.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/employee_remote_data_source.dart';
import '../data/repositories/employee_repository_impl.dart';
import '../domain/entities/employee.dart';
import '../domain/entities/employee_document.dart';
import '../domain/repositories/employee_repository.dart';

final employeeRemoteDataSourceProvider = Provider<EmployeeRemoteDataSource>(
  (ref) => EmployeeRemoteDataSource(ref.watch(dioClientProvider).dio),
);

final employeeRepositoryProvider = Provider<EmployeeRepository>(
  (ref) => EmployeeRepositoryImpl(ref.watch(employeeRemoteDataSourceProvider)),
);

final employeeListProvider = FutureProvider.autoDispose<List<Employee>>(
  (ref) => ref.watch(employeeRepositoryProvider).getAll(),
);

final myProfileProvider = FutureProvider.autoDispose<Employee>(
  (ref) => ref.watch(employeeRepositoryProvider).getMe(),
);

final employeeDetailProvider = FutureProvider.autoDispose.family<Employee, String>(
  (ref, id) => ref.watch(employeeRepositoryProvider).getById(id),
);

final departmentsProvider = FutureProvider.autoDispose<List<NamedRef>>(
  (ref) => ref.watch(employeeRepositoryProvider).getDepartments(),
);

final teamsProvider = FutureProvider.autoDispose.family<List<NamedRef>, String?>(
  (ref, departmentId) =>
      ref.watch(employeeRepositoryProvider).getTeams(departmentId: departmentId),
);

final myDocumentsProvider =
    FutureProvider.autoDispose<List<EmployeeDocument>>(
      (ref) => ref.watch(employeeRepositoryProvider).getMyDocuments(),
    );

final employeeDocumentsProvider = FutureProvider.autoDispose
    .family<List<EmployeeDocument>, String>(
      (ref, employeeId) =>
          ref.watch(employeeRepositoryProvider).getDocuments(employeeId),
    );
