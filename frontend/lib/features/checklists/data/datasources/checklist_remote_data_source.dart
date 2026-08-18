import 'package:dio/dio.dart';
import '../models/checklist_template_item_model.dart';
import '../models/employee_checklist_item_model.dart';

class ChecklistRemoteDataSource {
  const ChecklistRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ChecklistTemplateItemModel>> getTemplateItems(
    String type, {
    bool includeArchived = false,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/checklists/templates',
      queryParameters: {
        'type': type,
        'includeArchived': includeArchived.toString(),
      },
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(ChecklistTemplateItemModel.fromJson)
        .toList();
  }

  Future<ChecklistTemplateItemModel> createTemplateItem({
    required String type,
    required String title,
    String? description,
    String? appliesToWorkMode,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/checklists/templates',
      data: {
        'type': type,
        'title': title,
        'description': ?description,
        'appliesToWorkMode': ?appliesToWorkMode,
      },
    );
    return ChecklistTemplateItemModel.fromJson(response.data!);
  }

  Future<ChecklistTemplateItemModel> updateTemplateItem(
    String id, {
    required String title,
    String? description,
    String? appliesToWorkMode,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/checklists/templates/$id',
      data: {
        'title': title,
        'description': description,
        'appliesToWorkMode': appliesToWorkMode,
      },
    );
    return ChecklistTemplateItemModel.fromJson(response.data!);
  }

  Future<ChecklistTemplateItemModel> setTemplateItemArchived(
    String id, {
    required bool isArchived,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/checklists/templates/$id',
      data: {'isArchived': isArchived},
    );
    return ChecklistTemplateItemModel.fromJson(response.data!);
  }

  Future<List<ChecklistTemplateItemModel>> reorderTemplateItems(
    String type,
    List<String> orderedIds,
  ) async {
    final response = await _dio.patch<List<dynamic>>(
      '/checklists/templates/reorder',
      data: {'type': type, 'orderedIds': orderedIds},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(ChecklistTemplateItemModel.fromJson)
        .toList();
  }

  Future<void> deleteTemplateItem(String id) async {
    await _dio.delete('/checklists/templates/$id');
  }

  Future<List<EmployeeChecklistItemModel>> getMyChecklist(String type) async {
    final response = await _dio.get<List<dynamic>>(
      '/employees/me/checklist',
      queryParameters: {'type': type},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(EmployeeChecklistItemModel.fromJson)
        .toList();
  }

  Future<List<EmployeeChecklistItemModel>> getEmployeeChecklist(
    String employeeId,
    String type,
  ) async {
    final response = await _dio.get<List<dynamic>>(
      '/employees/$employeeId/checklist',
      queryParameters: {'type': type},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(EmployeeChecklistItemModel.fromJson)
        .toList();
  }

  Future<EmployeeChecklistItemModel> setChecklistItemCompleted(
    String employeeId,
    String itemId, {
    required bool isCompleted,
    String? note,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/employees/$employeeId/checklist/$itemId',
      data: {'isCompleted': isCompleted, 'note': ?note},
    );
    return EmployeeChecklistItemModel.fromJson(response.data!);
  }
}
