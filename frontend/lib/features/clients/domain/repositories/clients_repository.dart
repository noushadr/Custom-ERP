import '../entities/client.dart';
import '../entities/client_health_history_entry.dart';
import '../entities/client_health_summary.dart';
import '../entities/project.dart';
import '../entities/projects_summary.dart';
import '../entities/service.dart';

/// Covers Client + Service + Project — tightly coupled entities, one
/// repository, same convention as Leave bundling LeaveType+LeaveRequest.
abstract interface class ClientsRepository {
  Future<List<Client>> getClients({bool includeArchived = false});
  Future<Client> createClient({
    required String companyName,
    String? industry,
    String? website,
    String? country,
    String? address,
    String? primaryContactName,
    String? primaryContactEmail,
    String? primaryContactPhone,
    String? leadSource,
    String? notes,
  });
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
    String? leadSource,
    String? notes,
    bool? isArchived,
  });

  Future<ClientHealthSummary> getClientHealthSummary();
  Future<Client> updateClientHealth(
    String id, {
    required String status,
    List<String>? factors,
    String? notes,
  });
  Future<List<ClientHealthHistoryEntry>> getClientHealthHistory(String id);

  Future<List<Service>> getServices({bool includeArchived = false});
  Future<Service> createService({required String name, String? description});
  Future<Service> updateService(
    String id, {
    String? name,
    String? description,
    bool? isArchived,
  });

  Future<List<Project>> getProjects({String? status, String? clientId});
  Future<Project> getProject(String id);
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
  });
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
  });
  Future<ProjectsSummary> getProjectsSummary();
}
