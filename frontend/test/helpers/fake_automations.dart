import 'package:zera_erp/features/automations/domain/entities/automation.dart';
import 'package:zera_erp/features/automations/domain/entities/automation_execution_history_entry.dart';
import 'package:zera_erp/features/automations/domain/entities/automation_type.dart';
import 'package:zera_erp/features/automations/domain/repositories/automations_repository.dart';

Automation buildTestAutomation({
  String type = AutomationType.projectRenewalReminder,
  bool isActive = false,
  int? daysBefore = 7,
  String? updatedByName,
  DateTime? updatedAt,
}) {
  return Automation(
    type: type,
    isActive: isActive,
    daysBefore: daysBefore,
    updatedByName: updatedByName,
    updatedAt: updatedAt ?? DateTime(2026, 1, 1),
  );
}

AutomationExecutionHistoryEntry buildTestAutomationExecutionHistoryEntry({
  String id = 'history-1',
  String type = AutomationType.projectRenewalReminder,
  String triggeredBy = 'manual',
  String status = 'success',
  int itemsProcessed = 0,
  int notificationsCreated = 0,
  String? errorMessage,
  DateTime? runAt,
}) {
  return AutomationExecutionHistoryEntry(
    id: id,
    type: type,
    triggeredBy: triggeredBy,
    status: status,
    itemsProcessed: itemsProcessed,
    notificationsCreated: notificationsCreated,
    errorMessage: errorMessage,
    runAt: runAt ?? DateTime(2026, 1, 1),
  );
}

class FakeAutomationsRepository implements AutomationsRepository {
  FakeAutomationsRepository({
    List<Automation>? automations,
    this.history = const [],
  }) : automations =
           automations ??
           [
             buildTestAutomation(type: AutomationType.projectRenewalReminder),
             buildTestAutomation(type: AutomationType.taskDeadlineReminder),
             buildTestAutomation(
               type: AutomationType.annualLeaveReset,
               daysBefore: null,
             ),
           ];

  final List<Automation> automations;
  final List<AutomationExecutionHistoryEntry> history;

  /// The arguments passed to the most recent [updateAutomation] call.
  String? lastUpdatedType;
  bool? lastUpdatedIsActive;
  int? lastUpdatedDaysBefore;

  /// The type passed to the most recent [runNow] call.
  String? lastRunType;

  /// Incremented on every [getAutomations] call — used to confirm a
  /// mutation actually invalidated and re-fetched the list.
  int getAutomationsCallCount = 0;

  @override
  Future<List<Automation>> getAutomations() async {
    getAutomationsCallCount++;
    return automations;
  }

  @override
  Future<Automation> updateAutomation(
    String type, {
    bool? isActive,
    int? daysBefore,
  }) async {
    lastUpdatedType = type;
    lastUpdatedIsActive = isActive;
    lastUpdatedDaysBefore = daysBefore;
    final existing = automations.firstWhere(
      (a) => a.type == type,
      orElse: () => buildTestAutomation(type: type),
    );
    return buildTestAutomation(
      type: type,
      isActive: isActive ?? existing.isActive,
      daysBefore: daysBefore ?? existing.daysBefore,
      updatedByName: 'Jane Admin',
    );
  }

  @override
  Future<List<AutomationExecutionHistoryEntry>> getHistory({
    String? type,
  }) async => type == null
      ? history
      : history.where((h) => h.type == type).toList();

  @override
  Future<AutomationExecutionHistoryEntry> runNow(String type) async {
    lastRunType = type;
    return buildTestAutomationExecutionHistoryEntry(type: type);
  }
}
