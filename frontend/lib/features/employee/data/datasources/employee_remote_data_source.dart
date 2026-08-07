import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../shared/models/named_ref.dart';
import '../../domain/entities/employee_document.dart';
import '../../domain/entities/invite_employee_input.dart';
import '../../domain/entities/update_employee_input.dart';
import '../../domain/entities/update_my_profile_input.dart';
import '../models/audit_log_entry_model.dart';
import '../models/education_record_model.dart';
import '../models/employee_document_model.dart';
import '../models/employee_model.dart';
import '../models/salary_record_model.dart';

class EmployeeRemoteDataSource {
  const EmployeeRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<EmployeeModel>> getAll() async {
    final response = await _dio.get<List<dynamic>>('/employees');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(EmployeeModel.fromJson)
        .toList();
  }

  Future<EmployeeModel> getById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/employees/$id');
    return EmployeeModel.fromJson(response.data!);
  }

  Future<EmployeeModel> getMe() async {
    final response = await _dio.get<Map<String, dynamic>>('/employees/me');
    return EmployeeModel.fromJson(response.data!);
  }

  Future<List<EmployeeModel>> getMyDirectReports() async {
    final response = await _dio.get<List<dynamic>>(
      '/employees/me/direct-reports',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(EmployeeModel.fromJson)
        .toList();
  }

  Future<EmployeeModel> updateMe(UpdateMyProfileInput input) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/employees/me',
      data: input.toJson(),
    );
    return EmployeeModel.fromJson(response.data!);
  }

  Future<EmployeeModel> updateEmployee(
    String id,
    UpdateEmployeeInput input,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/employees/$id',
      data: input.toJson(),
    );
    return EmployeeModel.fromJson(response.data!);
  }

  Future<EmployeeModel> uploadMyPhoto(Uint8List bytes, String fileName) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/employees/me/photo',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      }),
    );
    return EmployeeModel.fromJson(response.data!);
  }

  Future<({EmployeeModel employee, String temporaryPassword})> invite(
    InviteEmployeeInput input,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/employees/invite',
      data: input.toJson(),
    );
    final data = response.data!;
    return (
      employee: EmployeeModel.fromJson(data['employee'] as Map<String, dynamic>),
      temporaryPassword: data['temporaryPassword'] as String,
    );
  }

  Future<List<NamedRef>> getDepartments() async {
    final response = await _dio.get<List<dynamic>>('/departments');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(NamedRef.fromJson)
        .toList();
  }

  Future<List<NamedRef>> getTeams({String? departmentId}) async {
    final response = await _dio.get<List<dynamic>>(
      '/teams',
      queryParameters: departmentId == null
          ? null
          : {'departmentId': departmentId},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(NamedRef.fromJson)
        .toList();
  }

  Future<List<EmployeeDocumentModel>> getMyDocuments() async {
    final response = await _dio.get<List<dynamic>>('/employees/me/documents');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(EmployeeDocumentModel.fromJson)
        .toList();
  }

  Future<EmployeeDocumentModel> uploadMyDocument(
    Uint8List bytes,
    String fileName, {
    DocumentType documentType = DocumentType.other,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/employees/me/documents',
      data: FormData.fromMap({
        'documentType': documentTypeToJson(documentType),
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      }),
    );
    return EmployeeDocumentModel.fromJson(response.data!);
  }

  Future<void> deleteMyDocument(String documentId) async {
    await _dio.delete('/employees/me/documents/$documentId');
  }

  Future<List<EmployeeDocumentModel>> getDocuments(String employeeId) async {
    final response = await _dio.get<List<dynamic>>(
      '/employees/$employeeId/documents',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(EmployeeDocumentModel.fromJson)
        .toList();
  }

  Future<EmployeeDocumentModel> uploadDocument(
    String employeeId,
    Uint8List bytes,
    String fileName, {
    DocumentType documentType = DocumentType.other,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/employees/$employeeId/documents',
      data: FormData.fromMap({
        'documentType': documentTypeToJson(documentType),
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      }),
    );
    return EmployeeDocumentModel.fromJson(response.data!);
  }

  Future<void> deleteDocument(String employeeId, String documentId) async {
    await _dio.delete('/employees/$employeeId/documents/$documentId');
  }

  Future<List<AuditLogEntryModel>> getMyAuditLog() async {
    final response = await _dio.get<List<dynamic>>('/employees/me/audit-log');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(AuditLogEntryModel.fromJson)
        .toList();
  }

  Future<List<AuditLogEntryModel>> getAuditLog(String employeeId) async {
    final response = await _dio.get<List<dynamic>>(
      '/employees/$employeeId/audit-log',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(AuditLogEntryModel.fromJson)
        .toList();
  }

  Future<List<AuditLogEntryModel>> getCompanyAuditLog() async {
    final response = await _dio.get<List<dynamic>>('/employees/audit-log');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(AuditLogEntryModel.fromJson)
        .toList();
  }

  Future<List<SalaryRecordModel>> getMySalaryHistory() async {
    final response = await _dio.get<List<dynamic>>(
      '/employees/me/salary-history',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(SalaryRecordModel.fromJson)
        .toList();
  }

  Future<List<SalaryRecordModel>> getSalaryHistory(String employeeId) async {
    final response = await _dio.get<List<dynamic>>(
      '/employees/$employeeId/salary-history',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(SalaryRecordModel.fromJson)
        .toList();
  }

  Future<SalaryRecordModel> addSalaryRecord(
    String employeeId, {
    required double amount,
    required String effectiveDate,
    String? note,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/employees/$employeeId/salary-history',
      data: {
        'amount': amount,
        'effectiveDate': effectiveDate,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return SalaryRecordModel.fromJson(response.data!);
  }

  Future<void> deleteSalaryRecord(String employeeId, String recordId) async {
    await _dio.delete('/employees/$employeeId/salary-history/$recordId');
  }

  Future<List<EducationRecordModel>> getMyEducationHistory() async {
    final response = await _dio.get<List<dynamic>>(
      '/employees/me/education-history',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(EducationRecordModel.fromJson)
        .toList();
  }

  Future<List<EducationRecordModel>> getEducationHistory(
    String employeeId,
  ) async {
    final response = await _dio.get<List<dynamic>>(
      '/employees/$employeeId/education-history',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(EducationRecordModel.fromJson)
        .toList();
  }

  Future<EducationRecordModel> addMyEducationRecord({
    required String degree,
    required String institution,
    required int yearCompleted,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/employees/me/education-history',
      data: {
        'degree': degree,
        'institution': institution,
        'yearCompleted': yearCompleted,
      },
    );
    return EducationRecordModel.fromJson(response.data!);
  }

  Future<EducationRecordModel> addEducationRecord(
    String employeeId, {
    required String degree,
    required String institution,
    required int yearCompleted,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/employees/$employeeId/education-history',
      data: {
        'degree': degree,
        'institution': institution,
        'yearCompleted': yearCompleted,
      },
    );
    return EducationRecordModel.fromJson(response.data!);
  }

  Future<void> deleteMyEducationRecord(String recordId) async {
    await _dio.delete('/employees/me/education-history/$recordId');
  }

  Future<void> deleteEducationRecord(
    String employeeId,
    String recordId,
  ) async {
    await _dio.delete('/employees/$employeeId/education-history/$recordId');
  }
}
