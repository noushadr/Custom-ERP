import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/automations_remote_data_source.dart';
import '../data/repositories/automations_repository_impl.dart';
import '../domain/entities/automation.dart';
import '../domain/entities/automation_execution_history_entry.dart';
import '../domain/repositories/automations_repository.dart';

final automationsRemoteDataSourceProvider =
    Provider<AutomationsRemoteDataSource>(
      (ref) =>
          AutomationsRemoteDataSource(ref.watch(dioClientProvider).dio),
    );

final automationsRepositoryProvider = Provider<AutomationsRepository>(
  (ref) =>
      AutomationsRepositoryImpl(ref.watch(automationsRemoteDataSourceProvider)),
);

final automationsListProvider = FutureProvider.autoDispose<List<Automation>>((
  ref,
) {
  ref.watch(authControllerProvider);
  return ref.watch(automationsRepositoryProvider).getAutomations();
});

final automationHistoryProvider = FutureProvider.autoDispose
    .family<List<AutomationExecutionHistoryEntry>, String>((ref, type) {
      ref.watch(authControllerProvider);
      return ref.watch(automationsRepositoryProvider).getHistory(type: type);
    });
