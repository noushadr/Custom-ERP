import 'package:zera_erp/features/checklists/domain/entities/checklist_template_item.dart';
import 'package:zera_erp/features/checklists/domain/entities/employee_checklist_item.dart';
import 'package:zera_erp/features/checklists/domain/repositories/checklist_repository.dart';

ChecklistTemplateItem buildTestChecklistTemplateItem({
  String id = 'template-1',
  String type = 'onboarding',
  String title = 'Acceptance of offer letter via email',
  String? description,
  int sortOrder = 0,
  String? appliesToWorkMode,
  bool isArchived = false,
}) {
  return ChecklistTemplateItem(
    id: id,
    type: type,
    title: title,
    description: description,
    sortOrder: sortOrder,
    appliesToWorkMode: appliesToWorkMode,
    isArchived: isArchived,
  );
}

EmployeeChecklistItem buildTestEmployeeChecklistItem({
  String id = 'item-1',
  String employeeId = 'employee-1',
  String? templateItemId = 'template-1',
  String type = 'onboarding',
  String title = 'Acceptance of offer letter via email',
  int sortOrder = 0,
  bool isCompleted = false,
  DateTime? completedAt,
  String? completedByName,
  String? note,
}) {
  return EmployeeChecklistItem(
    id: id,
    employeeId: employeeId,
    templateItemId: templateItemId,
    type: type,
    title: title,
    sortOrder: sortOrder,
    isCompleted: isCompleted,
    completedAt: completedAt,
    completedByName: completedByName,
    note: note,
  );
}

class FakeChecklistRepository implements ChecklistRepository {
  FakeChecklistRepository({
    this.templateItems = const [],
    this.myChecklist = const [],
    this.employeeChecklist = const [],
    this.createTemplateItemError,
    this.updateTemplateItemError,
    this.deleteTemplateItemError,
    this.reorderTemplateItemsError,
    this.setChecklistItemCompletedError,
  });

  final List<ChecklistTemplateItem> templateItems;
  final List<EmployeeChecklistItem> myChecklist;
  final List<EmployeeChecklistItem> employeeChecklist;
  final Object? createTemplateItemError;
  final Object? updateTemplateItemError;
  final Object? deleteTemplateItemError;
  final Object? reorderTemplateItemsError;
  final Object? setChecklistItemCompletedError;

  String? lastDeletedTemplateItemId;
  List<String>? lastReorderedIds;
  ({String employeeId, String itemId, bool isCompleted, String? note})?
  lastSetChecklistItemCompletedInput;

  @override
  Future<List<ChecklistTemplateItem>> getTemplateItems(
    String type, {
    bool includeArchived = false,
  }) async => templateItems
      .where((i) => i.type == type && (includeArchived || !i.isArchived))
      .toList();

  @override
  Future<ChecklistTemplateItem> createTemplateItem({
    required String type,
    required String title,
    String? description,
    String? appliesToWorkMode,
  }) async {
    if (createTemplateItemError != null) throw createTemplateItemError!;
    return buildTestChecklistTemplateItem(
      type: type,
      title: title,
      description: description,
      appliesToWorkMode: appliesToWorkMode,
    );
  }

  @override
  Future<ChecklistTemplateItem> updateTemplateItem(
    String id, {
    required String title,
    String? description,
    String? appliesToWorkMode,
  }) async {
    if (updateTemplateItemError != null) throw updateTemplateItemError!;
    return buildTestChecklistTemplateItem(
      id: id,
      title: title,
      description: description,
      appliesToWorkMode: appliesToWorkMode,
    );
  }

  @override
  Future<ChecklistTemplateItem> setTemplateItemArchived(
    String id, {
    required bool isArchived,
  }) async => buildTestChecklistTemplateItem(id: id, isArchived: isArchived);

  @override
  Future<List<ChecklistTemplateItem>> reorderTemplateItems(
    String type,
    List<String> orderedIds,
  ) async {
    lastReorderedIds = orderedIds;
    if (reorderTemplateItemsError != null) throw reorderTemplateItemsError!;
    return templateItems;
  }

  @override
  Future<void> deleteTemplateItem(String id) async {
    lastDeletedTemplateItemId = id;
    if (deleteTemplateItemError != null) throw deleteTemplateItemError!;
  }

  @override
  Future<List<EmployeeChecklistItem>> getMyChecklist(String type) async =>
      myChecklist.where((i) => i.type == type).toList();

  @override
  Future<List<EmployeeChecklistItem>> getEmployeeChecklist(
    String employeeId,
    String type,
  ) async => employeeChecklist.where((i) => i.type == type).toList();

  @override
  Future<EmployeeChecklistItem> setChecklistItemCompleted(
    String employeeId,
    String itemId, {
    required bool isCompleted,
    String? note,
  }) async {
    lastSetChecklistItemCompletedInput = (
      employeeId: employeeId,
      itemId: itemId,
      isCompleted: isCompleted,
      note: note,
    );
    if (setChecklistItemCompletedError != null) {
      throw setChecklistItemCompletedError!;
    }
    return buildTestEmployeeChecklistItem(
      id: itemId,
      employeeId: employeeId,
      isCompleted: isCompleted,
      note: note,
    );
  }
}
