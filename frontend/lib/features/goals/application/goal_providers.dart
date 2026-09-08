import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/goal_remote_data_source.dart';
import '../data/repositories/goal_repository_impl.dart';
import '../domain/entities/goal.dart';
import '../domain/repositories/goal_repository.dart';

final goalRemoteDataSourceProvider = Provider<GoalRemoteDataSource>(
  (ref) => GoalRemoteDataSource(ref.watch(dioClientProvider).dio),
);

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => GoalRepositoryImpl(ref.watch(goalRemoteDataSourceProvider)),
);

// Every provider below re-watches authControllerProvider purely to create a
// dependency edge, so switching identity (impersonate/returnToAdmin/logout)
// triggers a refetch — see the longer explanation in employee_providers.dart.

final myGoalsProvider = FutureProvider.autoDispose<List<Goal>>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(goalRepositoryProvider).getMine();
});

final teamGoalsProvider = FutureProvider.autoDispose<List<Goal>>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(goalRepositoryProvider).getTeam();
});

final allGoalsProvider = FutureProvider.autoDispose<List<Goal>>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(goalRepositoryProvider).getAll();
});
