import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/task_remote_data_source.dart';
import '../data/repositories/task_repository_impl.dart';
import '../domain/entities/task.dart';
import '../domain/entities/task_audit_log_entry.dart';
import '../domain/entities/task_comment.dart';
import '../domain/repositories/task_repository.dart';

final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>(
  (ref) => TaskRemoteDataSource(ref.watch(dioClientProvider).dio),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepositoryImpl(ref.watch(taskRemoteDataSourceProvider)),
);

// Every provider below re-watches authControllerProvider purely to create a
// dependency edge, so switching identity (impersonate/returnToAdmin/logout)
// triggers a refetch — see the longer explanation in employee_providers.dart.

final myTasksProvider = FutureProvider.autoDispose<List<Task>>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(taskRepositoryProvider).getMyTasks();
});

final tasksAssignedByMeProvider = FutureProvider.autoDispose<List<Task>>((
  ref,
) {
  ref.watch(authControllerProvider);
  return ref.watch(taskRepositoryProvider).getTasksAssignedByMe();
});

final teamTasksProvider = FutureProvider.autoDispose<List<Task>>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(taskRepositoryProvider).getTeamTasks();
});

final taskProvider = FutureProvider.autoDispose.family<Task, String>((
  ref,
  id,
) {
  ref.watch(authControllerProvider);
  return ref.watch(taskRepositoryProvider).getTask(id);
});

final taskHistoryProvider = FutureProvider.autoDispose
    .family<List<TaskAuditLogEntry>, String>((ref, id) {
      ref.watch(authControllerProvider);
      return ref.watch(taskRepositoryProvider).getHistory(id);
    });

final taskCommentsProvider = FutureProvider.autoDispose
    .family<List<TaskComment>, String>((ref, id) {
      ref.watch(authControllerProvider);
      return ref.watch(taskRepositoryProvider).getComments(id);
    });
