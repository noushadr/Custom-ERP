import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/checklist_remote_data_source.dart';
import '../data/repositories/checklist_repository_impl.dart';
import '../domain/entities/checklist_template_item.dart';
import '../domain/entities/employee_checklist_item.dart';
import '../domain/repositories/checklist_repository.dart';

final checklistRemoteDataSourceProvider = Provider<ChecklistRemoteDataSource>(
  (ref) => ChecklistRemoteDataSource(ref.watch(dioClientProvider).dio),
);

final checklistRepositoryProvider = Provider<ChecklistRepository>(
  (ref) =>
      ChecklistRepositoryImpl(ref.watch(checklistRemoteDataSourceProvider)),
);

// Every provider below re-watches authControllerProvider purely to create a
// dependency edge, so switching identity (impersonate/returnToAdmin/logout)
// triggers a refetch — see the longer explanation in employee_providers.dart.

/// Keyed by (type, includeArchived) — the checklist templates settings page
/// toggles both independently.
final checklistTemplateItemsProvider = FutureProvider.autoDispose
    .family<List<ChecklistTemplateItem>, ({String type, bool includeArchived})>(
  (ref, query) {
    ref.watch(authControllerProvider);
    return ref
        .watch(checklistRepositoryProvider)
        .getTemplateItems(query.type, includeArchived: query.includeArchived);
  },
);

final myChecklistProvider = FutureProvider.autoDispose
    .family<List<EmployeeChecklistItem>, String>((ref, type) {
      ref.watch(authControllerProvider);
      return ref.watch(checklistRepositoryProvider).getMyChecklist(type);
    });

final employeeChecklistProvider = FutureProvider.autoDispose
    .family<List<EmployeeChecklistItem>, ({String employeeId, String type})>(
  (ref, query) {
    ref.watch(authControllerProvider);
    return ref
        .watch(checklistRepositoryProvider)
        .getEmployeeChecklist(query.employeeId, query.type);
  },
);
