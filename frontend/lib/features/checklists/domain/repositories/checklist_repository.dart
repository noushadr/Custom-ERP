import '../entities/checklist_template_item.dart';
import '../entities/employee_checklist_item.dart';

abstract interface class ChecklistRepository {
  Future<List<ChecklistTemplateItem>> getTemplateItems(
    String type, {
    bool includeArchived = false,
  });

  /// Requires `employees.manage`.
  Future<ChecklistTemplateItem> createTemplateItem({
    required String type,
    required String title,
    String? description,
    String? appliesToWorkMode,
  });

  /// Always replaces all three fields — used by the edit form, which shows
  /// (and thus always submits) all of them together. Requires
  /// `employees.manage`.
  Future<ChecklistTemplateItem> updateTemplateItem(
    String id, {
    required String title,
    String? description,
    String? appliesToWorkMode,
  });

  /// Requires `employees.manage`.
  Future<ChecklistTemplateItem> setTemplateItemArchived(
    String id, {
    required bool isArchived,
  });

  /// Requires `employees.manage`.
  Future<List<ChecklistTemplateItem>> reorderTemplateItems(
    String type,
    List<String> orderedIds,
  );

  /// Requires `employees.manage`. Throws [ChecklistException] if employee
  /// checklists already reference this item — archive it instead.
  Future<void> deleteTemplateItem(String id);

  Future<List<EmployeeChecklistItem>> getMyChecklist(String type);

  /// Requires `employees.manage`.
  Future<List<EmployeeChecklistItem>> getEmployeeChecklist(
    String employeeId,
    String type,
  );

  /// Requires `employees.manage`.
  Future<EmployeeChecklistItem> setChecklistItemCompleted(
    String employeeId,
    String itemId, {
    required bool isCompleted,
    String? note,
  });
}
