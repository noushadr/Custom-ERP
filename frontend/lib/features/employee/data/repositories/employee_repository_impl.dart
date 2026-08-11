import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../shared/models/named_ref.dart';
import '../../domain/entities/audit_log_entry.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/education_record.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/employee_document.dart';
import '../../domain/entities/invite_employee_input.dart';
import '../../domain/entities/salary_record.dart';
import '../../domain/entities/update_employee_input.dart';
import '../../domain/entities/update_my_profile_input.dart';
import '../../domain/entities/upcoming_birthday.dart';
import '../../domain/exceptions/employee_exception.dart';
import '../../domain/repositories/employee_repository.dart';
import '../datasources/employee_remote_data_source.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  const EmployeeRepositoryImpl(this._remoteDataSource);

  final EmployeeRemoteDataSource _remoteDataSource;

  @override
  Future<List<Employee>> getAll() =>
      _guard(() => _remoteDataSource.getAll());

  @override
  Future<Employee> getById(String id) =>
      _guard(() => _remoteDataSource.getById(id));

  @override
  Future<Employee> getMe() => _guard(() => _remoteDataSource.getMe());

  @override
  Future<List<UpcomingBirthday>> getUpcomingBirthdays() =>
      _guard(() => _remoteDataSource.getUpcomingBirthdays());

  @override
  Future<List<Employee>> getMyDirectReports() =>
      _guard(() => _remoteDataSource.getMyDirectReports());

  @override
  Future<Employee> updateMe(UpdateMyProfileInput input) =>
      _guard(() => _remoteDataSource.updateMe(input));

  @override
  Future<Employee> updateEmployee(String id, UpdateEmployeeInput input) =>
      _guard(() => _remoteDataSource.updateEmployee(id, input));

  @override
  Future<Employee> updateEmployeeTags(
    String id, {
    List<String>? skills,
    List<String>? certifications,
  }) => _guard(
    () => _remoteDataSource.updateEmployeeTags(
      id,
      skills: skills,
      certifications: certifications,
    ),
  );

  @override
  Future<Employee> uploadMyPhoto(Uint8List bytes, String fileName) =>
      _guard(() => _remoteDataSource.uploadMyPhoto(bytes, fileName));

  @override
  Future<({Employee employee, String temporaryPassword})> invite(
    InviteEmployeeInput input,
  ) => _guard(() => _remoteDataSource.invite(input));

  @override
  Future<List<Department>> getDepartments({bool includeArchived = false}) =>
      _guard(
        () =>
            _remoteDataSource.getDepartments(includeArchived: includeArchived),
      );

  @override
  Future<Department> createDepartment({
    required String name,
    String? description,
    String? headEmployeeId,
  }) => _guard(
    () => _remoteDataSource.createDepartment(
      name: name,
      description: description,
      headEmployeeId: headEmployeeId,
    ),
  );

  @override
  Future<Department> updateDepartment(
    String id, {
    required String name,
    String? description,
    String? headEmployeeId,
  }) => _guard(
    () => _remoteDataSource.updateDepartment(
      id,
      name: name,
      description: description,
      headEmployeeId: headEmployeeId,
    ),
  );

  @override
  Future<Department> setDepartmentArchived(
    String id, {
    required bool isArchived,
  }) => _guard(
    () => _remoteDataSource.setDepartmentArchived(id, isArchived: isArchived),
  );

  @override
  Future<void> deleteDepartment(String id) =>
      _guard(() => _remoteDataSource.deleteDepartment(id));

  @override
  Future<List<NamedRef>> getTeams({String? departmentId}) =>
      _guard(() => _remoteDataSource.getTeams(departmentId: departmentId));

  @override
  Future<List<EmployeeDocument>> getMyDocuments() =>
      _guard(() => _remoteDataSource.getMyDocuments());

  @override
  Future<EmployeeDocument> uploadMyDocument(
    Uint8List bytes,
    String fileName, {
    DocumentType documentType = DocumentType.other,
  }) => _guard(
    () => _remoteDataSource.uploadMyDocument(
      bytes,
      fileName,
      documentType: documentType,
    ),
  );

  @override
  Future<void> deleteMyDocument(String documentId) =>
      _guard(() => _remoteDataSource.deleteMyDocument(documentId));

  @override
  Future<List<EmployeeDocument>> getDocuments(String employeeId) =>
      _guard(() => _remoteDataSource.getDocuments(employeeId));

  @override
  Future<EmployeeDocument> uploadDocument(
    String employeeId,
    Uint8List bytes,
    String fileName, {
    DocumentType documentType = DocumentType.other,
  }) => _guard(
    () => _remoteDataSource.uploadDocument(
      employeeId,
      bytes,
      fileName,
      documentType: documentType,
    ),
  );

  @override
  Future<void> deleteDocument(String employeeId, String documentId) =>
      _guard(() => _remoteDataSource.deleteDocument(employeeId, documentId));

  @override
  Future<List<AuditLogEntry>> getMyAuditLog() =>
      _guard(() => _remoteDataSource.getMyAuditLog());

  @override
  Future<List<AuditLogEntry>> getAuditLog(String employeeId) =>
      _guard(() => _remoteDataSource.getAuditLog(employeeId));

  @override
  Future<List<AuditLogEntry>> getCompanyAuditLog() =>
      _guard(() => _remoteDataSource.getCompanyAuditLog());

  @override
  Future<List<SalaryRecord>> getMySalaryHistory() =>
      _guard(() => _remoteDataSource.getMySalaryHistory());

  @override
  Future<List<SalaryRecord>> getSalaryHistory(String employeeId) =>
      _guard(() => _remoteDataSource.getSalaryHistory(employeeId));

  @override
  Future<SalaryRecord> addSalaryRecord(
    String employeeId, {
    required double amount,
    required String effectiveDate,
    String? note,
  }) => _guard(
    () => _remoteDataSource.addSalaryRecord(
      employeeId,
      amount: amount,
      effectiveDate: effectiveDate,
      note: note,
    ),
  );

  @override
  Future<void> deleteSalaryRecord(String employeeId, String recordId) =>
      _guard(() => _remoteDataSource.deleteSalaryRecord(employeeId, recordId));

  @override
  Future<List<EducationRecord>> getMyEducationHistory() =>
      _guard(() => _remoteDataSource.getMyEducationHistory());

  @override
  Future<List<EducationRecord>> getEducationHistory(String employeeId) =>
      _guard(() => _remoteDataSource.getEducationHistory(employeeId));

  @override
  Future<EducationRecord> addMyEducationRecord({
    required String degree,
    required String institution,
    required int yearCompleted,
  }) => _guard(
    () => _remoteDataSource.addMyEducationRecord(
      degree: degree,
      institution: institution,
      yearCompleted: yearCompleted,
    ),
  );

  @override
  Future<EducationRecord> addEducationRecord(
    String employeeId, {
    required String degree,
    required String institution,
    required int yearCompleted,
  }) => _guard(
    () => _remoteDataSource.addEducationRecord(
      employeeId,
      degree: degree,
      institution: institution,
      yearCompleted: yearCompleted,
    ),
  );

  @override
  Future<void> deleteMyEducationRecord(String recordId) =>
      _guard(() => _remoteDataSource.deleteMyEducationRecord(recordId));

  @override
  Future<void> deleteEducationRecord(String employeeId, String recordId) =>
      _guard(
        () => _remoteDataSource.deleteEducationRecord(employeeId, recordId),
      );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw EmployeeException(_mapError(error));
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
    if (status == 404) return 'Not found.';
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
