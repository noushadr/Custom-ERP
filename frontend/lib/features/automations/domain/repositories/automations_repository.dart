import '../entities/automation.dart';
import '../entities/automation_execution_history_entry.dart';

abstract interface class AutomationsRepository {
  Future<List<Automation>> getAutomations();

  Future<Automation> updateAutomation(
    String type, {
    bool? isActive,
    int? daysBefore,
  });

  Future<List<AutomationExecutionHistoryEntry>> getHistory({String? type});

  Future<AutomationExecutionHistoryEntry> runNow(String type);
}
