import 'dart:typed_data';
import '../entities/asset.dart';
import '../entities/audit_log_entry.dart';
import '../entities/department.dart';
import '../entities/education_record.dart';
import '../entities/employee.dart';
import '../entities/employee_document.dart';
import '../entities/invite_employee_input.dart';
import '../entities/paginated_audit_log.dart';
import '../entities/salary_record.dart';
import '../entities/update_employee_input.dart';
import '../entities/update_my_profile_input.dart';
import '../entities/upcoming_birthday.dart';
import '../entities/upcoming_work_anniversary.dart';

abstract interface class EmployeeRepository {
  /// Throws [EmployeeException] on failure.
  Future<List<Employee>> getAll();

  Future<Employee> getById(String id);

  Future<Employee> getMe();

  /// Employees with a birthday in the next 7 days, soonest first. Requires
  /// `employees.manage`.
  Future<List<UpcomingBirthday>> getUpcomingBirthdays();

  /// Employees marking a work anniversary in the next 7 days, soonest first.
  /// Requires `employees.manage`.
  Future<List<UpcomingWorkAnniversary>> getUpcomingWorkAnniversaries();

  /// Employees who report to the current user, if any.
  Future<List<Employee>> getMyDirectReports();

  Future<Employee> updateMe(UpdateMyProfileInput input);

  /// Requires `employees.manage`.
  Future<Employee> updateEmployee(String id, UpdateEmployeeInput input);

  /// Updates only the given field(s), leaving everything else on the record
  /// untouched — unlike [updateEmployee], which always sends the full field
  /// set. Requires `employees.manage`.
  Future<Employee> updateEmployeeTags(
    String id, {
    List<String>? skills,
    List<String>? certifications,
  });

  Future<Employee> uploadMyPhoto(Uint8List bytes, String fileName);

  /// Requires `employees.manage`.
  Future<Employee> uploadPhoto(String id, Uint8List bytes, String fileName);

  Future<({Employee employee, String temporaryPassword})> invite(
    InviteEmployeeInput input,
  );

  Future<List<Department>> getDepartments({bool includeArchived = false});

  /// Requires `departments.manage`.
  Future<Department> createDepartment({
    required String name,
    String? description,
    String? headEmployeeId,
  });

  /// Requires `departments.manage`.
  Future<Department> updateDepartment(
    String id, {
    required String name,
    String? description,
    String? headEmployeeId,
  });

  /// Requires `departments.manage`.
  Future<Department> setDepartmentArchived(String id, {required bool isArchived});

  /// Requires `departments.manage`. Fails if any employees are still
  /// assigned to this department — archive it instead.
  Future<void> deleteDepartment(String id);

  Future<List<EmployeeDocument>> getMyDocuments();

  Future<EmployeeDocument> uploadMyDocument(
    Uint8List bytes,
    String fileName, {
    DocumentType documentType = DocumentType.other,
  });

  Future<void> deleteMyDocument(String documentId);

  /// Requires `employees.manage`.
  Future<List<EmployeeDocument>> getDocuments(String employeeId);

  /// Requires `employees.manage`.
  Future<EmployeeDocument> uploadDocument(
    String employeeId,
    Uint8List bytes,
    String fileName, {
    DocumentType documentType = DocumentType.other,
  });

  /// Requires `employees.manage`.
  Future<void> deleteDocument(String employeeId, String documentId);

  Future<List<AuditLogEntry>> getMyAuditLog();

  /// Requires `employees.manage`.
  Future<List<AuditLogEntry>> getAuditLog(String employeeId);

  /// Combined, paginated, and searchable feed across all employees. Requires
  /// `audit.viewAll`.
  Future<PaginatedAuditLog> getCompanyAuditLog({
    int page = 1,
    int limit = 10,
    String? search,
  });

  /// Chronological, oldest first — the first entry is the joining salary,
  /// the last is the current salary.
  Future<List<SalaryRecord>> getMySalaryHistory();

  /// Requires `employees.manage`.
  Future<List<SalaryRecord>> getSalaryHistory(String employeeId);

  /// Requires `employees.manage` — never self-service, even for HR viewing
  /// their own profile.
  Future<SalaryRecord> addSalaryRecord(
    String employeeId, {
    required double amount,
    required String effectiveDate,
    String? note,
  });

  /// Requires `employees.manage`.
  Future<void> deleteSalaryRecord(String employeeId, String recordId);

  /// Chronological, oldest first.
  Future<List<EducationRecord>> getMyEducationHistory();

  /// Requires `employees.manage`.
  Future<List<EducationRecord>> getEducationHistory(String employeeId);

  Future<EducationRecord> addMyEducationRecord({
    required String degree,
    required String institution,
    required int yearCompleted,
  });

  /// Requires `employees.manage`.
  Future<EducationRecord> addEducationRecord(
    String employeeId, {
    required String degree,
    required String institution,
    required int yearCompleted,
  });

  Future<void> deleteMyEducationRecord(String recordId);

  /// Requires `employees.manage`.
  Future<void> deleteEducationRecord(String employeeId, String recordId);

  /// Assets currently assigned to the caller.
  Future<List<Asset>> getMyAssets();

  /// Assets currently assigned to [employeeId]. Requires `employees.manage`.
  Future<List<Asset>> getAssets(String employeeId);

  /// Creates a brand-new asset and assigns it to [employeeId] immediately.
  /// Requires `employees.manage`.
  Future<Asset> createAndAssignAsset(
    String employeeId, {
    required String name,
    double? value,
  });

  /// Edits an assigned asset's own details (not its assignment). Requires
  /// `employees.manage`.
  Future<Asset> updateAsset(
    String employeeId,
    String assetId, {
    String? name,
    double? value,
  });

  /// Permanently removes an asset assigned to [employeeId]. Requires
  /// `employees.manage`.
  Future<void> deleteAsset(String employeeId, String assetId);
}
