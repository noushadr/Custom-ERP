import 'dart:typed_data';
import 'package:zera_erp/features/employee/domain/entities/asset.dart';
import 'package:zera_erp/features/employee/domain/entities/audit_log_entry.dart';
import 'package:zera_erp/features/employee/domain/entities/department.dart';
import 'package:zera_erp/features/employee/domain/entities/employee.dart';
import 'package:zera_erp/features/employee/domain/entities/employee_document.dart';
import 'package:zera_erp/features/employee/domain/entities/education_record.dart';
import 'package:zera_erp/features/employee/domain/entities/invite_employee_input.dart';
import 'package:zera_erp/features/employee/domain/entities/paginated_audit_log.dart';
import 'package:zera_erp/features/employee/domain/entities/salary_record.dart';
import 'package:zera_erp/features/employee/domain/entities/update_employee_input.dart';
import 'package:zera_erp/features/employee/domain/entities/update_my_profile_input.dart';
import 'package:zera_erp/features/employee/domain/entities/upcoming_birthday.dart';
import 'package:zera_erp/features/employee/domain/entities/upcoming_work_anniversary.dart';
import 'package:zera_erp/features/employee/domain/repositories/employee_repository.dart';
import 'package:zera_erp/shared/models/named_ref.dart';

Employee buildTestEmployee({
  String id = 'employee-1',
  String userId = 'user-1',
  String employeeCode = 'ZC-00001',
  String email = 'jane.doe@zeracreative.com',
  String role = 'Employee',
  String fullName = 'Jane Doe',
  String? designation = 'Software Engineer',
  NamedRef? department,
  NamedRef? reportingManager,
  int profileCompletionPercentage = 25,
  List<String> skills = const [],
  List<String> certifications = const [],
  String joiningDate = '2026-01-01',
  String employmentStatus = 'active',
  String workMode = 'on_site',
}) {
  final parts = fullName.split(' ');
  return Employee(
    id: id,
    userId: userId,
    employeeCode: employeeCode,
    email: email,
    role: role,
    accountStatus: 'active',
    firstName: parts.first,
    lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
    fullName: fullName,
    profilePhotoUrl: null,
    designation: designation,
    department: department,
    reportingManager: reportingManager,
    employmentType: 'full_time',
    employmentStatus: employmentStatus,
    workMode: workMode,
    joiningDate: joiningDate,
    dateOfLeaving: null,
    dateOfBirth: null,
    personalEmail: null,
    phoneNumber: null,
    emergencyContactName: null,
    emergencyContactPhone: null,
    emergencyContactRelation: null,
    address: null,
    bankName: null,
    accountTitle: null,
    accountNumber: null,
    branchCode: null,
    iban: null,
    skills: skills,
    certifications: certifications,
    profileCompletionPercentage: profileCompletionPercentage,
  );
}

Asset buildTestAsset({
  String id = 'asset-1',
  String name = 'Dell Laptop',
  String status = 'assigned',
  String? assignedEmployeeId = 'employee-1',
  DateTime? assignedAt,
  double? value = 150000,
}) {
  return Asset(
    id: id,
    name: name,
    status: status,
    assignedEmployeeId: assignedEmployeeId,
    assignedAt: assignedAt ?? DateTime(2026, 1, 1),
    value: value,
    createdAt: DateTime(2026, 1, 1),
  );
}

class FakeEmployeeRepository implements EmployeeRepository {
  FakeEmployeeRepository({
    this.employees = const [],
    Employee? me,
    this.departments = const [],
    this.inviteResult,
    this.inviteError,
    this.updateMeResult,
    this.updateMeError,
    this.updateEmployeeResult,
    this.updateEmployeeError,
    this.uploadMyPhotoResult,
    this.uploadMyPhotoError,
    this.uploadPhotoResult,
    this.uploadPhotoError,
    this.documents = const [],
    this.auditLog = const [],
    this.salaryHistory = const [],
    this.educationHistory = const [],
    this.directReports = const [],
    this.getMeError,
    this.updateEmployeeTagsError,
    this.createDepartmentResult,
    this.createDepartmentError,
    this.updateDepartmentResult,
    this.updateDepartmentError,
    this.setDepartmentArchivedResult,
    this.setDepartmentArchivedError,
    this.deleteDepartmentError,
    this.upcomingBirthdays = const [],
    this.getUpcomingBirthdaysError,
    this.upcomingWorkAnniversaries = const [],
    this.getUpcomingWorkAnniversariesError,
    this.assets = const [],
    this.createAndAssignAssetError,
    this.updateAssetError,
    this.deleteAssetError,
  }) : me = me ?? buildTestEmployee();

  final List<Employee> employees;
  final Employee me;
  final Object? getMeError;
  final List<UpcomingBirthday> upcomingBirthdays;
  final Object? getUpcomingBirthdaysError;
  final List<UpcomingWorkAnniversary> upcomingWorkAnniversaries;
  final Object? getUpcomingWorkAnniversariesError;
  final List<Department> departments;
  final ({Employee employee, String temporaryPassword})? inviteResult;
  final Object? inviteError;
  final Employee? updateMeResult;
  final Object? updateMeError;
  final Employee? updateEmployeeResult;
  final Object? updateEmployeeError;
  final Object? updateEmployeeTagsError;
  final Department? createDepartmentResult;
  final Object? createDepartmentError;
  final Department? updateDepartmentResult;
  final Object? updateDepartmentError;
  final Department? setDepartmentArchivedResult;
  final Object? setDepartmentArchivedError;
  final Object? deleteDepartmentError;

  /// The `id` passed to the most recent [updateEmployeeTags] call.
  String? lastUpdateTagsId;
  List<String>? lastUpdateTagsSkills;
  List<String>? lastUpdateTagsCertifications;

  /// The arguments passed to the most recent [createDepartment] call.
  ({String name, String? description, String? headEmployeeId})?
  lastCreateDepartmentInput;

  /// The `id` and arguments passed to the most recent [updateDepartment] call.
  ({String id, String name, String? description, String? headEmployeeId})?
  lastUpdateDepartmentInput;

  /// The arguments passed to the most recent [setDepartmentArchived] call.
  ({String id, bool isArchived})? lastSetDepartmentArchivedInput;

  /// The `id` passed to the most recent [deleteDepartment] call.
  String? lastDeleteDepartmentId;

  /// The input passed to the most recent [updateMe] call.
  UpdateMyProfileInput? lastUpdateMeInput;
  final Employee? uploadMyPhotoResult;
  final Object? uploadMyPhotoError;
  final Employee? uploadPhotoResult;
  final Object? uploadPhotoError;
  final List<EmployeeDocument> documents;
  final List<AuditLogEntry> auditLog;
  final List<SalaryRecord> salaryHistory;
  final List<EducationRecord> educationHistory;
  final List<Employee> directReports;
  final List<Asset> assets;
  final Object? createAndAssignAssetError;
  final Object? updateAssetError;
  final Object? deleteAssetError;

  /// The arguments passed to the most recent [createAndAssignAsset] call.
  ({String employeeId, String name})? lastCreateAndAssignAssetInput;

  /// The `assetId` passed to the most recent [updateAsset] call.
  String? lastUpdateAssetId;

  /// The `assetId` passed to the most recent [deleteAsset] call.
  String? lastDeleteAssetId;

  /// The `id` passed to the most recent [uploadPhoto] call.
  String? lastUploadPhotoId;

  @override
  Future<List<Employee>> getAll() async => employees;

  @override
  Future<Employee> getById(String id) async =>
      employees.firstWhere((e) => e.id == id, orElse: () => me);

  @override
  Future<Employee> getMe() async {
    if (getMeError != null) throw getMeError!;
    return me;
  }

  @override
  Future<List<UpcomingBirthday>> getUpcomingBirthdays() async {
    if (getUpcomingBirthdaysError != null) throw getUpcomingBirthdaysError!;
    return upcomingBirthdays;
  }

  @override
  Future<List<UpcomingWorkAnniversary>> getUpcomingWorkAnniversaries() async {
    if (getUpcomingWorkAnniversariesError != null) {
      throw getUpcomingWorkAnniversariesError!;
    }
    return upcomingWorkAnniversaries;
  }

  @override
  Future<List<Employee>> getMyDirectReports() async => directReports;

  @override
  Future<Employee> updateMe(UpdateMyProfileInput input) async {
    lastUpdateMeInput = input;
    if (updateMeError != null) throw updateMeError!;
    return updateMeResult ?? me;
  }

  @override
  Future<Employee> updateEmployee(String id, UpdateEmployeeInput input) async {
    if (updateEmployeeError != null) throw updateEmployeeError!;
    return updateEmployeeResult ?? me;
  }

  @override
  Future<Employee> updateEmployeeTags(
    String id, {
    List<String>? skills,
    List<String>? certifications,
  }) async {
    lastUpdateTagsId = id;
    lastUpdateTagsSkills = skills;
    lastUpdateTagsCertifications = certifications;
    if (updateEmployeeTagsError != null) throw updateEmployeeTagsError!;
    return updateEmployeeResult ?? me;
  }

  @override
  Future<Employee> uploadMyPhoto(Uint8List bytes, String fileName) async {
    if (uploadMyPhotoError != null) throw uploadMyPhotoError!;
    return uploadMyPhotoResult ?? me;
  }

  @override
  Future<Employee> uploadPhoto(
    String id,
    Uint8List bytes,
    String fileName,
  ) async {
    lastUploadPhotoId = id;
    if (uploadPhotoError != null) throw uploadPhotoError!;
    return uploadPhotoResult ?? me;
  }

  @override
  Future<({Employee employee, String temporaryPassword})> invite(
    InviteEmployeeInput input,
  ) async {
    if (inviteError != null) throw inviteError!;
    return inviteResult!;
  }

  @override
  Future<List<Department>> getDepartments({
    bool includeArchived = false,
  }) async => includeArchived
      ? departments
      : departments.where((d) => !d.isArchived).toList();

  @override
  Future<Department> createDepartment({
    required String name,
    String? description,
    String? headEmployeeId,
  }) async {
    lastCreateDepartmentInput = (
      name: name,
      description: description,
      headEmployeeId: headEmployeeId,
    );
    if (createDepartmentError != null) throw createDepartmentError!;
    return createDepartmentResult ??
        Department(
          id: 'department-1',
          name: name,
          description: description,
          headEmployeeId: headEmployeeId,
        );
  }

  @override
  Future<Department> updateDepartment(
    String id, {
    required String name,
    String? description,
    String? headEmployeeId,
  }) async {
    lastUpdateDepartmentInput = (
      id: id,
      name: name,
      description: description,
      headEmployeeId: headEmployeeId,
    );
    if (updateDepartmentError != null) throw updateDepartmentError!;
    return updateDepartmentResult ??
        Department(
          id: id,
          name: name,
          description: description,
          headEmployeeId: headEmployeeId,
        );
  }

  @override
  Future<Department> setDepartmentArchived(
    String id, {
    required bool isArchived,
  }) async {
    lastSetDepartmentArchivedInput = (id: id, isArchived: isArchived);
    if (setDepartmentArchivedError != null) {
      throw setDepartmentArchivedError!;
    }
    return setDepartmentArchivedResult ??
        Department(id: id, name: 'Department', isArchived: isArchived);
  }

  @override
  Future<void> deleteDepartment(String id) async {
    lastDeleteDepartmentId = id;
    if (deleteDepartmentError != null) throw deleteDepartmentError!;
  }

  @override
  Future<List<EmployeeDocument>> getMyDocuments() async => documents;

  @override
  Future<EmployeeDocument> uploadMyDocument(
    Uint8List bytes,
    String fileName, {
    DocumentType documentType = DocumentType.other,
  }) async => documents.first;

  @override
  Future<void> deleteMyDocument(String documentId) async {}

  @override
  Future<List<EmployeeDocument>> getDocuments(String employeeId) async =>
      documents;

  @override
  Future<EmployeeDocument> uploadDocument(
    String employeeId,
    Uint8List bytes,
    String fileName, {
    DocumentType documentType = DocumentType.other,
  }) async => documents.first;

  @override
  Future<void> deleteDocument(String employeeId, String documentId) async {}

  @override
  Future<List<AuditLogEntry>> getMyAuditLog() async => auditLog;

  @override
  Future<List<AuditLogEntry>> getAuditLog(String employeeId) async =>
      auditLog;

  @override
  Future<PaginatedAuditLog> getCompanyAuditLog({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    var filtered = auditLog;
    if (search != null && search.isNotEmpty) {
      final lower = search.toLowerCase();
      bool matches(String? value) => value?.toLowerCase().contains(lower) ?? false;
      filtered = filtered
          .where(
            (e) =>
                matches(e.employeeName) ||
                matches(e.fieldLabel) ||
                matches(e.actorName) ||
                matches(e.oldValue) ||
                matches(e.newValue),
          )
          .toList();
    }
    final total = filtered.length;
    final start = (page - 1) * limit;
    final pageItems = start >= filtered.length
        ? <AuditLogEntry>[]
        : filtered.skip(start).take(limit).toList();
    return PaginatedAuditLog(
      items: pageItems,
      total: total,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<List<SalaryRecord>> getMySalaryHistory() async => salaryHistory;

  @override
  Future<List<SalaryRecord>> getSalaryHistory(String employeeId) async =>
      salaryHistory;

  @override
  Future<SalaryRecord> addSalaryRecord(
    String employeeId, {
    required double amount,
    required String effectiveDate,
    String? note,
  }) async => salaryHistory.isNotEmpty
      ? salaryHistory.last
      : SalaryRecord(
          id: 'salary-1',
          amount: amount,
          effectiveDate: effectiveDate,
          note: note,
          createdAt: DateTime(2026, 1, 1),
        );

  @override
  Future<void> deleteSalaryRecord(String employeeId, String recordId) async {}

  @override
  Future<List<EducationRecord>> getMyEducationHistory() async =>
      educationHistory;

  @override
  Future<List<EducationRecord>> getEducationHistory(String employeeId) async =>
      educationHistory;

  @override
  Future<EducationRecord> addMyEducationRecord({
    required String degree,
    required String institution,
    required int yearCompleted,
  }) async => educationHistory.isNotEmpty
      ? educationHistory.last
      : EducationRecord(
          id: 'education-1',
          degree: degree,
          institution: institution,
          yearCompleted: yearCompleted,
          createdAt: DateTime(2026, 1, 1),
        );

  @override
  Future<EducationRecord> addEducationRecord(
    String employeeId, {
    required String degree,
    required String institution,
    required int yearCompleted,
  }) async => educationHistory.isNotEmpty
      ? educationHistory.last
      : EducationRecord(
          id: 'education-1',
          degree: degree,
          institution: institution,
          yearCompleted: yearCompleted,
          createdAt: DateTime(2026, 1, 1),
        );

  @override
  Future<void> deleteMyEducationRecord(String recordId) async {}

  @override
  Future<void> deleteEducationRecord(
    String employeeId,
    String recordId,
  ) async {}

  @override
  Future<List<Asset>> getMyAssets() async => assets;

  @override
  Future<List<Asset>> getAssets(String employeeId) async => assets;

  @override
  Future<Asset> createAndAssignAsset(
    String employeeId, {
    required String name,
    double? value,
  }) async {
    lastCreateAndAssignAssetInput = (employeeId: employeeId, name: name);
    if (createAndAssignAssetError != null) throw createAndAssignAssetError!;
    return buildTestAsset(name: name, value: value, assignedEmployeeId: employeeId);
  }

  @override
  Future<Asset> updateAsset(
    String employeeId,
    String assetId, {
    String? name,
    double? value,
  }) async {
    lastUpdateAssetId = assetId;
    if (updateAssetError != null) throw updateAssetError!;
    return buildTestAsset(
      id: assetId,
      name: name ?? 'Dell Laptop',
      value: value,
      assignedEmployeeId: employeeId,
    );
  }

  @override
  Future<void> deleteAsset(String employeeId, String assetId) async {
    lastDeleteAssetId = assetId;
    if (deleteAssetError != null) throw deleteAssetError!;
  }
}
