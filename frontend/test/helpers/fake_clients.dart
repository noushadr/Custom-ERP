import 'package:zera_erp/features/clients/domain/entities/client.dart';
import 'package:zera_erp/features/clients/domain/entities/project.dart';
import 'package:zera_erp/features/clients/domain/entities/project_refs.dart';
import 'package:zera_erp/features/clients/domain/entities/projects_summary.dart';
import 'package:zera_erp/features/clients/domain/entities/service.dart';
import 'package:zera_erp/features/clients/domain/repositories/clients_repository.dart';

Client buildTestClient({
  String id = 'client-1',
  String companyName = 'Acme Co',
  String? industry = 'Retail',
  String? website,
  String? address,
  String? primaryContactName = 'Jane Client',
  String? primaryContactEmail,
  String? primaryContactPhone,
  String? notes,
  bool isArchived = false,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Client(
    id: id,
    companyName: companyName,
    industry: industry,
    website: website,
    address: address,
    primaryContactName: primaryContactName,
    primaryContactEmail: primaryContactEmail,
    primaryContactPhone: primaryContactPhone,
    notes: notes,
    isArchived: isArchived,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    updatedAt: updatedAt ?? DateTime(2026, 1, 1),
  );
}

Service buildTestService({
  String id = 'service-1',
  String name = 'SEO',
  String? description,
  bool isArchived = false,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Service(
    id: id,
    name: name,
    description: description,
    isArchived: isArchived,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    updatedAt: updatedAt ?? DateTime(2026, 1, 1),
  );
}

Project buildTestProject({
  String id = 'project-1',
  String clientId = 'client-1',
  String clientName = 'Acme Co',
  String name = 'Website Revamp',
  String type = 'one_time',
  String status = 'active',
  String startDate = '2026-01-01',
  String? endDate,
  String? renewalDate,
  double originalClientPrice = 1000,
  double deductionRate = 20,
  double? netPrice,
  double cost = 200,
  double? profit,
  String? notes,
  List<ProjectEmployeeRef> assignedEmployees = const [],
  List<ProjectDepartmentRef> targetDepartments = const [],
  List<ProjectServiceRef> services = const [],
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final resolvedNetPrice =
      netPrice ?? originalClientPrice * (1 - deductionRate / 100);
  return Project(
    id: id,
    clientId: clientId,
    clientName: clientName,
    name: name,
    type: type,
    status: status,
    startDate: startDate,
    endDate: endDate,
    renewalDate: renewalDate,
    originalClientPrice: originalClientPrice,
    deductionRate: deductionRate,
    netPrice: resolvedNetPrice,
    cost: cost,
    profit: profit ?? (resolvedNetPrice - cost),
    notes: notes,
    assignedEmployees: assignedEmployees,
    targetDepartments: targetDepartments,
    services: services,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    updatedAt: updatedAt ?? DateTime(2026, 1, 1),
  );
}

ProjectsSummary buildTestProjectsSummary({
  int activeCount = 0,
  int onHoldCount = 0,
  int completedCount = 0,
  int cancelledCount = 0,
  double activeMonthlyRecurringRevenue = 0,
  double oneTimeRevenueThisYear = 0,
}) {
  return ProjectsSummary(
    activeCount: activeCount,
    onHoldCount: onHoldCount,
    completedCount: completedCount,
    cancelledCount: cancelledCount,
    activeMonthlyRecurringRevenue: activeMonthlyRecurringRevenue,
    oneTimeRevenueThisYear: oneTimeRevenueThisYear,
  );
}

class FakeClientsRepository implements ClientsRepository {
  FakeClientsRepository({
    this.clients = const [],
    this.services = const [],
    this.projects = const [],
    this.projectsSummary,
  });

  final List<Client> clients;
  final List<Service> services;
  final List<Project> projects;
  final ProjectsSummary? projectsSummary;

  /// The `companyName` passed to the most recent [createClient] call.
  String? lastCreatedCompanyName;

  /// The `name` passed to the most recent [createService] call.
  String? lastCreatedServiceName;

  /// The arguments passed to the most recent [createProject] call.
  String? lastCreatedProjectName;
  double? lastCreatedProjectPrice;

  @override
  Future<List<Client>> getClients({bool includeArchived = false}) async =>
      includeArchived ? clients : clients.where((c) => !c.isArchived).toList();

  @override
  Future<Client> createClient({
    required String companyName,
    String? industry,
    String? website,
    String? address,
    String? primaryContactName,
    String? primaryContactEmail,
    String? primaryContactPhone,
    String? notes,
  }) async {
    lastCreatedCompanyName = companyName;
    return buildTestClient(companyName: companyName);
  }

  @override
  Future<Client> updateClient(
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
  }) async => buildTestClient(id: id, isArchived: isArchived ?? false);

  @override
  Future<List<Service>> getServices({bool includeArchived = false}) async =>
      includeArchived
      ? services
      : services.where((s) => !s.isArchived).toList();

  @override
  Future<Service> createService({
    required String name,
    String? description,
  }) async {
    lastCreatedServiceName = name;
    return buildTestService(name: name, description: description);
  }

  @override
  Future<Service> updateService(
    String id, {
    String? name,
    String? description,
    bool? isArchived,
  }) async => buildTestService(id: id, isArchived: isArchived ?? false);

  @override
  Future<List<Project>> getProjects({String? status, String? clientId}) async {
    return projects
        .where((p) => status == null || p.status == status)
        .where((p) => clientId == null || p.clientId == clientId)
        .toList();
  }

  @override
  Future<Project> getProject(String id) async =>
      projects.firstWhere((p) => p.id == id, orElse: () => buildTestProject(id: id));

  @override
  Future<Project> createProject({
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
    lastCreatedProjectName = name;
    lastCreatedProjectPrice = originalClientPrice;
    return buildTestProject(
      clientId: clientId,
      name: name,
      type: type,
      originalClientPrice: originalClientPrice,
      deductionRate: deductionRate ?? 20,
      cost: cost ?? 0,
    );
  }

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
    double? originalClientPrice,
    double? deductionRate,
    double? cost,
    String? notes,
    List<String>? assignedEmployeeIds,
    List<String>? targetDepartmentIds,
    List<String>? serviceIds,
  }) async => buildTestProject(id: id);

  @override
  Future<ProjectsSummary> getProjectsSummary() async =>
      projectsSummary ?? buildTestProjectsSummary();
}
