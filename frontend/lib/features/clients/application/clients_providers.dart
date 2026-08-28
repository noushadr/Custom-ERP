import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/clients_remote_data_source.dart';
import '../data/repositories/clients_repository_impl.dart';
import '../domain/entities/client.dart';
import '../domain/entities/client_health_history_entry.dart';
import '../domain/entities/client_health_summary.dart';
import '../domain/entities/project.dart';
import '../domain/entities/projects_summary.dart';
import '../domain/entities/service.dart';
import '../domain/repositories/clients_repository.dart';

final clientsRemoteDataSourceProvider = Provider<ClientsRemoteDataSource>(
  (ref) => ClientsRemoteDataSource(ref.watch(dioClientProvider).dio),
);

final clientsRepositoryProvider = Provider<ClientsRepository>(
  (ref) => ClientsRepositoryImpl(ref.watch(clientsRemoteDataSourceProvider)),
);

// Every provider below re-watches authControllerProvider purely to create a
// dependency edge, so switching identity (impersonate/returnToAdmin/logout)
// triggers a refetch — see the longer explanation in employee_providers.dart.

final clientsListProvider = FutureProvider.autoDispose
    .family<List<Client>, bool>((ref, includeArchived) {
      ref.watch(authControllerProvider);
      return ref
          .watch(clientsRepositoryProvider)
          .getClients(includeArchived: includeArchived);
    });

final clientProvider = FutureProvider.autoDispose.family<Client, String>((
  ref,
  id,
) async {
  ref.watch(authControllerProvider);
  // No single-client GET beyond the list — resolve from the already-fetched
  // list rather than adding a redundant endpoint.
  final clients = await ref.watch(clientsListProvider(true).future);
  return clients.firstWhere((client) => client.id == id);
});

final servicesListProvider = FutureProvider.autoDispose
    .family<List<Service>, bool>((ref, includeArchived) {
      ref.watch(authControllerProvider);
      return ref
          .watch(clientsRepositoryProvider)
          .getServices(includeArchived: includeArchived);
    });

final projectsListProvider = FutureProvider.autoDispose
    .family<List<Project>, ({String? status, String? clientId})>((
      ref,
      filters,
    ) {
      ref.watch(authControllerProvider);
      return ref
          .watch(clientsRepositoryProvider)
          .getProjects(status: filters.status, clientId: filters.clientId);
    });

final projectProvider = FutureProvider.autoDispose.family<Project, String>((
  ref,
  id,
) {
  ref.watch(authControllerProvider);
  return ref.watch(clientsRepositoryProvider).getProject(id);
});

final projectsSummaryProvider = FutureProvider.autoDispose<ProjectsSummary>((
  ref,
) {
  ref.watch(authControllerProvider);
  return ref.watch(clientsRepositoryProvider).getProjectsSummary();
});

final clientHealthSummaryProvider =
    FutureProvider.autoDispose<ClientHealthSummary>((ref) {
      ref.watch(authControllerProvider);
      return ref.watch(clientsRepositoryProvider).getClientHealthSummary();
    });

final clientHealthHistoryProvider = FutureProvider.autoDispose
    .family<List<ClientHealthHistoryEntry>, String>((ref, clientId) {
      ref.watch(authControllerProvider);
      return ref
          .watch(clientsRepositoryProvider)
          .getClientHealthHistory(clientId);
    });
