import 'dart:typed_data';
import 'package:zera_erp/features/employee/domain/entities/audit_log_entry.dart';
import 'package:zera_erp/features/employee/domain/entities/employee.dart';
import 'package:zera_erp/features/employee/domain/entities/employee_document.dart';
import 'package:zera_erp/features/employee/domain/entities/education_record.dart';
import 'package:zera_erp/features/employee/domain/entities/invite_employee_input.dart';
import 'package:zera_erp/features/employee/domain/entities/salary_record.dart';
import 'package:zera_erp/features/employee/domain/entities/update_employee_input.dart';
import 'package:zera_erp/features/employee/domain/entities/update_my_profile_input.dart';
import 'package:zera_erp/features/employee/domain/repositories/employee_repository.dart';
import 'package:zera_erp/shared/models/named_ref.dart';

Employee buildTestEmployee({
  String id = 'employee-1',
  String employeeCode = 'ZC-00001',
  String email = 'jane.doe@zeracreative.com',
  String role = 'Employee',
  String fullName = 'Jane Doe',
  String? designation = 'Software Engineer',
  NamedRef? department,
  NamedRef? reportingManager,
  int profileCompletionPercentage = 25,
}) {
  final parts = fullName.split(' ');
  return Employee(
    id: id,
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
    team: null,
    reportingManager: reportingManager,
    employmentType: 'full_time',
    employmentStatus: 'active',
    workMode: 'on_site',
    joiningDate: '2026-01-01',
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
    skills: const [],
    certifications: const [],
    profileCompletionPercentage: profileCompletionPercentage,
  );
}

class FakeEmployeeRepository implements EmployeeRepository {
  FakeEmployeeRepository({
    this.employees = const [],
    Employee? me,
    this.departments = const [],
    this.teams = const [],
    this.inviteResult,
    this.inviteError,
    this.updateMeResult,
    this.updateMeError,
    this.updateEmployeeResult,
    this.updateEmployeeError,
    this.uploadMyPhotoResult,
    this.uploadMyPhotoError,
    this.documents = const [],
    this.auditLog = const [],
    this.salaryHistory = const [],
    this.educationHistory = const [],
  }) : me = me ?? buildTestEmployee();

  final List<Employee> employees;
  final Employee me;
  final List<NamedRef> departments;
  final List<NamedRef> teams;
  final ({Employee employee, String temporaryPassword})? inviteResult;
  final Object? inviteError;
  final Employee? updateMeResult;
  final Object? updateMeError;
  final Employee? updateEmployeeResult;
  final Object? updateEmployeeError;
  final Employee? uploadMyPhotoResult;
  final Object? uploadMyPhotoError;
  final List<EmployeeDocument> documents;
  final List<AuditLogEntry> auditLog;
  final List<SalaryRecord> salaryHistory;
  final List<EducationRecord> educationHistory;

  @override
  Future<List<Employee>> getAll() async => employees;

  @override
  Future<Employee> getById(String id) async =>
      employees.firstWhere((e) => e.id == id, orElse: () => me);

  @override
  Future<Employee> getMe() async => me;

  @override
  Future<Employee> updateMe(UpdateMyProfileInput input) async {
    if (updateMeError != null) throw updateMeError!;
    return updateMeResult ?? me;
  }

  @override
  Future<Employee> updateEmployee(String id, UpdateEmployeeInput input) async {
    if (updateEmployeeError != null) throw updateEmployeeError!;
    return updateEmployeeResult ?? me;
  }

  @override
  Future<Employee> uploadMyPhoto(Uint8List bytes, String fileName) async {
    if (uploadMyPhotoError != null) throw uploadMyPhotoError!;
    return uploadMyPhotoResult ?? me;
  }

  @override
  Future<({Employee employee, String temporaryPassword})> invite(
    InviteEmployeeInput input,
  ) async {
    if (inviteError != null) throw inviteError!;
    return inviteResult!;
  }

  @override
  Future<List<NamedRef>> getDepartments() async => departments;

  @override
  Future<List<NamedRef>> getTeams({String? departmentId}) async => teams;

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
  Future<List<AuditLogEntry>> getCompanyAuditLog() async => auditLog;

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
}
