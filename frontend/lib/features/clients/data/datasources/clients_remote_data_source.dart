import 'package:dio/dio.dart';
import '../models/client_health_history_entry_model.dart';
import '../models/client_health_summary_model.dart';
import '../models/client_model.dart';
import '../models/project_model.dart';
import '../models/projects_summary_model.dart';
import '../models/service_model.dart';

class ClientsRemoteDataSource {
  const ClientsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ClientModel>> getClients({bool includeArchived = false}) async {
    final response = await _dio.get<List<dynamic>>(
      '/clients',
      queryParameters: {'includeArchived': includeArchived.toString()},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(ClientModel.fromJson)
        .toList();
  }

  Future<ClientModel> createClient({
    required String companyName,
    String? industry,
    String? website,
    String? address,
    String? primaryContactName,
    String? primaryContactEmail,
    String? primaryContactPhone,
    String? notes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/clients',
      data: {
        'companyName': companyName,
        'industry': ?industry,
        'website': ?website,
        'address': ?address,
        'primaryContactName': ?primaryContactName,
        'primaryContactEmail': ?primaryContactEmail,
        'primaryContactPhone': ?primaryContactPhone,
        'notes': ?notes,
      },
    );
    return ClientModel.fromJson(response.data!);
  }

  Future<ClientModel> updateClient(
    String id, {
    String? companyName,
    String? industry,
    String? website,
    String? address,
    String? primaryContactName,
    String? primaryContactEmail,
    String? primaryContactPhone,
    String? notes,
    bool? isArchived,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/clients/$id',
      data: {
        'companyName': ?companyName,
        'industry': ?industry,
        'website': ?website,
        'address': ?address,
        'primaryContactName': ?primaryContactName,
        'primaryContactEmail': ?primaryContactEmail,
        'primaryContactPhone': ?primaryContactPhone,
        'notes': ?notes,
        'isArchived': ?isArchived,
      },
    );
    return ClientModel.fromJson(response.data!);
  }

  Future<ClientHealthSummaryModel> getClientHealthSummary() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/clients/health-summary',
    );
    return ClientHealthSummaryModel.fromJson(response.data!);
  }

  Future<ClientModel> updateClientHealth(
    String id, {
    required String status,
    List<String>? factors,
    String? notes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/clients/$id/health',
      data: {'status': status, 'factors': ?factors, 'notes': ?notes},
    );
    return ClientModel.fromJson(response.data!);
  }

  Future<List<ClientHealthHistoryEntryModel>> getClientHealthHistory(
    String id,
  ) async {
    final response = await _dio.get<List<dynamic>>(
      '/clients/$id/health-history',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(ClientHealthHistoryEntryModel.fromJson)
        .toList();
  }

  Future<List<ServiceModel>> getServices({
    bool includeArchived = false,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/services',
      queryParameters: {'includeArchived': includeArchived.toString()},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(ServiceModel.fromJson)
        .toList();
  }

  Future<ServiceModel> createService({
    required String name,
    String? description,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/services',
      data: {'name': name, 'description': ?description},
    );
    return ServiceModel.fromJson(response.data!);
  }

  Future<ServiceModel> updateService(
    String id, {
    String? name,
    String? description,
    bool? isArchived,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/services/$id',
      data: {
        'name': ?name,
        'description': ?description,
        'isArchived': ?isArchived,
      },
    );
    return ServiceModel.fromJson(response.data!);
  }

  Future<List<ProjectModel>> getProjects({
    String? status,
    String? clientId,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/projects',
      queryParameters: {'status': ?status, 'clientId': ?clientId},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(ProjectModel.fromJson)
        .toList();
  }

  Future<ProjectModel> getProject(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/projects/$id');
    return ProjectModel.fromJson(response.data!);
  }

  Future<ProjectsSummaryModel> getProjectsSummary() async {
    final response = await _dio.get<Map<String, dynamic>>('/projects/summary');
    return ProjectsSummaryModel.fromJson(response.data!);
  }

  Future<ProjectModel> createProject({
    required String clientId,
    required String name,
    required String type,
    String? status,
    required String startDate,
    String? endDate,
    String? renewalDate,
    required double originalClientPrice,
    double? deductionRate,
    double? cost,
    String? notes,
    List<String>? assignedEmployeeIds,
    List<String>? targetDepartmentIds,
    List<String>? serviceIds,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/projects',
      data: {
        'clientId': clientId,
        'name': name,
        'type': type,
        'status': ?status,
        'startDate': startDate,
        'endDate': ?endDate,
        'renewalDate': ?renewalDate,
        'originalClientPrice': originalClientPrice,
        'deductionRate': ?deductionRate,
        'cost': ?cost,
        'notes': ?notes,
        'assignedEmployeeIds': ?assignedEmployeeIds,
        'targetDepartmentIds': ?targetDepartmentIds,
        'serviceIds': ?serviceIds,
      },
    );
    return ProjectModel.fromJson(response.data!);
  }

  Future<ProjectModel> updateProject(
    String id, {
    String? clientId,
    String? name,
    String? type,
    String? status,
    String? startDate,
    String? endDate,
    String? renewalDate,
    double? originalClientPrice,
    double? deductionRate,
    double? cost,
    String? notes,
    String? paymentStatus,
    double? amountPaid,
    List<String>? assignedEmployeeIds,
    List<String>? targetDepartmentIds,
    List<String>? serviceIds,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/projects/$id',
      data: {
        'clientId': ?clientId,
        'name': ?name,
        'type': ?type,
        'status': ?status,
        'startDate': ?startDate,
        'endDate': ?endDate,
        'renewalDate': ?renewalDate,
        'originalClientPrice': ?originalClientPrice,
        'deductionRate': ?deductionRate,
        'cost': ?cost,
        'notes': ?notes,
        'paymentStatus': ?paymentStatus,
        'amountPaid': ?amountPaid,
        'assignedEmployeeIds': ?assignedEmployeeIds,
        'targetDepartmentIds': ?targetDepartmentIds,
        'serviceIds': ?serviceIds,
      },
    );
    return ProjectModel.fromJson(response.data!);
  }
}
