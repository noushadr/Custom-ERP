import 'dart:typed_data';
import '../../../../shared/models/named_ref.dart';
import '../entities/audit_log_entry.dart';
import '../entities/education_record.dart';
import '../entities/employee.dart';
import '../entities/employee_document.dart';
import '../entities/invite_employee_input.dart';
import '../entities/salary_record.dart';
import '../entities/update_employee_input.dart';
import '../entities/update_my_profile_input.dart';

abstract interface class EmployeeRepository {
  /// Throws [EmployeeException] on failure.
  Future<List<Employee>> getAll();

  Future<Employee> getById(String id);

  Future<Employee> getMe();

  /// Employees who report to the current user, if any.
  Future<List<Employee>> getMyDirectReports();

  Future<Employee> updateMe(UpdateMyProfileInput input);

  /// Requires `employees.manage`.
  Future<Employee> updateEmployee(String id, UpdateEmployeeInput input);

  Future<Employee> uploadMyPhoto(Uint8List bytes, String fileName);

  Future<({Employee employee, String temporaryPassword})> invite(
    InviteEmployeeInput input,
  );

  Future<List<NamedRef>> getDepartments();

  Future<List<NamedRef>> getTeams({String? departmentId});

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

  /// Combined feed across all employees. Requires `audit.viewAll`.
  Future<List<AuditLogEntry>> getCompanyAuditLog();

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
}
