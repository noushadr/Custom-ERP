import 'package:dio/dio.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/client_health_history_entry.dart';
import '../../domain/entities/client_health_summary.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/projects_summary.dart';
import '../../domain/entities/service.dart';
import '../../domain/exceptions/client_exception.dart';
import '../../domain/repositories/clients_repository.dart';
import '../datasources/clients_remote_data_source.dart';

class ClientsRepositoryImpl implements ClientsRepository {
  const ClientsRepositoryImpl(this._remoteDataSource);

  final ClientsRemoteDataSource _remoteDataSource;

  @override
  Future<List<Client>> getClients({bool includeArchived = false}) =>
      _guard(() => _remoteDataSource.getClients(includeArchived: includeArchived));

  @override
  Future<Client> createClient({
    required String companyName,
    String? industry,
    String? website,
    String? country,
    String? address,
    String? primaryContactName,
    String? primaryContactEmail,
    String? primaryContactPhone,
    String? notes,
  }) => _guard(
    () => _remoteDataSource.createClient(
      companyName: companyName,
      industry: industry,
      website: website,
      country: country,
      address: address,
      primaryContactName: primaryContactName,
      primaryContactEmail: primaryContactEmail,
      primaryContactPhone: primaryContactPhone,
      notes: notes,
    ),
  );

  @override
  Future<Client> updateClient(
    String id, {
    String? companyName,
    String? industry,
    String? website,
    String? country,
    String? address,
    String? primaryContactName,
    String? primaryContactEmail,
    String? primaryContactPhone,
    String? notes,
    bool? isArchived,
  }) => _guard(
    () => _remoteDataSource.updateClient(
      id,
      companyName: companyName,
      industry: industry,
      website: website,
      country: country,
      address: address,
      primaryContactName: primaryContactName,
      primaryContactEmail: primaryContactEmail,
      primaryContactPhone: primaryContactPhone,
      notes: notes,
      isArchived: isArchived,
    ),
  );

  @override
  Future<ClientHealthSummary> getClientHealthSummary() =>
      _guard(() => _remoteDataSource.getClientHealthSummary());

  @override
  Future<Client> updateClientHealth(
    String id, {
    required String status,
    List<String>? factors,
    String? notes,
  }) => _guard(
    () => _remoteDataSource.updateClientHealth(
      id,
      status: status,
      factors: factors,
      notes: notes,
    ),
  );

  @override
  Future<List<ClientHealthHistoryEntry>> getClientHealthHistory(String id) =>
      _guard(() => _remoteDataSource.getClientHealthHistory(id));

  @override
  Future<List<Service>> getServices({bool includeArchived = false}) => _guard(
    () => _remoteDataSource.getServices(includeArchived: includeArchived),
  );

  @override
  Future<Service> createService({required String name, String? description}) =>
      _guard(
        () => _remoteDataSource.createService(
          name: name,
          description: description,
        ),
      );

  @override
  Future<Service> updateService(
    String id, {
    String? name,
    String? description,
    bool? isArchived,
  }) => _guard(
    () => _remoteDataSource.updateService(
      id,
      name: name,
      description: description,
      isArchived: isArchived,
    ),
  );

  @override
  Future<List<Project>> getProjects({String? status, String? clientId}) =>
      _guard(
        () => _remoteDataSource.getProjects(status: status, clientId: clientId),
      );

  @override
  Future<Project> getProject(String id) =>
      _guard(() => _remoteDataSource.getProject(id));

  @override
  Future<ProjectsSummary> getProjectsSummary() =>
      _guard(() => _remoteDataSource.getProjectsSummary());

  @override
  Future<Project> createProject({
    required String clientId,
    required String name,
    required String type,
    String? status,
    required String startDate,
    String? endDate,
    String? renewalDate,
    String? notes,
    String? packageName,
    String? backlinksTarget,
    String? seoSheetName,
    String? projectFolderName,
    String? workingEmailAccount,
    String? ahrefsAccount,
    List<String>? assignedEmployeeIds,
    List<String>? targetDepartmentIds,
    List<String>? serviceIds,
  }) => _guard(
    () => _remoteDataSource.createProject(
      clientId: clientId,
      name: name,
      type: type,
      status: status,
      startDate: startDate,
      endDate: endDate,
      renewalDate: renewalDate,
      notes: notes,
      packageName: packageName,
      backlinksTarget: backlinksTarget,
      seoSheetName: seoSheetName,
      projectFolderName: projectFolderName,
      workingEmailAccount: workingEmailAccount,
      ahrefsAccount: ahrefsAccount,
      assignedEmployeeIds: assignedEmployeeIds,
      targetDepartmentIds: targetDepartmentIds,
      serviceIds: serviceIds,
    ),
  );

  @override
  Future<Project> updateProject(
    String id, {
    String? clientId,
    String? name,
    String? type,
    String? status,
    String? startDate,
    String? endDate,
    String? renewalDate,
    String? notes,
    String? packageName,
    String? backlinksTarget,
    String? seoSheetName,
    String? projectFolderName,
    String? workingEmailAccount,
    String? ahrefsAccount,
    List<String>? assignedEmployeeIds,
    List<String>? targetDepartmentIds,
    List<String>? serviceIds,
  }) => _guard(
    () => _remoteDataSource.updateProject(
      id,
      clientId: clientId,
      name: name,
      type: type,
      status: status,
      startDate: startDate,
      endDate: endDate,
      renewalDate: renewalDate,
      notes: notes,
      packageName: packageName,
      backlinksTarget: backlinksTarget,
      seoSheetName: seoSheetName,
      projectFolderName: projectFolderName,
      workingEmailAccount: workingEmailAccount,
      ahrefsAccount: ahrefsAccount,
      assignedEmployeeIds: assignedEmployeeIds,
      targetDepartmentIds: targetDepartmentIds,
      serviceIds: serviceIds,
    ),
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw ClientException(_mapError(error));
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
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
