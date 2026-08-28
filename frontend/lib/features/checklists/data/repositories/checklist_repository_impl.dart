import 'package:dio/dio.dart';
import '../../domain/entities/checklist_template_item.dart';
import '../../domain/entities/employee_checklist_item.dart';
import '../../domain/exceptions/checklist_exception.dart';
import '../../domain/repositories/checklist_repository.dart';
import '../datasources/checklist_remote_data_source.dart';

class ChecklistRepositoryImpl implements ChecklistRepository {
  const ChecklistRepositoryImpl(this._remoteDataSource);

  final ChecklistRemoteDataSource _remoteDataSource;

  @override
  Future<List<ChecklistTemplateItem>> getTemplateItems(
    String type, {
    bool includeArchived = false,
  }) => _guard(
    () => _remoteDataSource.getTemplateItems(
      type,
      includeArchived: includeArchived,
    ),
  );

  @override
  Future<ChecklistTemplateItem> createTemplateItem({
    required String type,
    required String title,
    String? description,
    String? appliesToWorkMode,
  }) => _guard(
    () => _remoteDataSource.createTemplateItem(
      type: type,
      title: title,
      description: description,
      appliesToWorkMode: appliesToWorkMode,
    ),
  );

  @override
  Future<ChecklistTemplateItem> updateTemplateItem(
    String id, {
    required String title,
    String? description,
    String? appliesToWorkMode,
  }) => _guard(
    () => _remoteDataSource.updateTemplateItem(
      id,
      title: title,
      description: description,
      appliesToWorkMode: appliesToWorkMode,
    ),
  );

  @override
  Future<ChecklistTemplateItem> setTemplateItemArchived(
    String id, {
    required bool isArchived,
  }) => _guard(
    () => _remoteDataSource.setTemplateItemArchived(
      id,
      isArchived: isArchived,
    ),
  );

  @override
  Future<List<ChecklistTemplateItem>> reorderTemplateItems(
    String type,
    List<String> orderedIds,
  ) => _guard(
    () => _remoteDataSource.reorderTemplateItems(type, orderedIds),
  );

  @override
  Future<void> deleteTemplateItem(String id) =>
      _guard(() => _remoteDataSource.deleteTemplateItem(id));

  @override
  Future<List<EmployeeChecklistItem>> getMyChecklist(String type) =>
      _guard(() => _remoteDataSource.getMyChecklist(type));

  @override
  Future<List<EmployeeChecklistItem>> getEmployeeChecklist(
    String employeeId,
    String type,
  ) => _guard(
    () => _remoteDataSource.getEmployeeChecklist(employeeId, type),
  );

  @override
  Future<EmployeeChecklistItem> setChecklistItemCompleted(
    String employeeId,
    String itemId, {
    required bool isCompleted,
    String? note,
  }) => _guard(
    () => _remoteDataSource.setChecklistItemCompleted(
      employeeId,
      itemId,
      isCompleted: isCompleted,
      note: note,
    ),
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw ChecklistException(_mapError(error));
    }
  }

  String _mapError(DioException error) {
    final status = error.response?.statusCode;
    if (status == 400) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (data is Map && data['message'] is List) {
        return (data['message'] as List).join(', ');
      }
      return 'Invalid request.';
    }
    if (status == 403) return "You don't have permission to do that.";
    if (status == 404) return 'That could not be found.';
    if (status == 409) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'This conflicts with existing data.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
