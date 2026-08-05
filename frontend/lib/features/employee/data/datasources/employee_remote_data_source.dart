import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../shared/models/named_ref.dart';
import '../../domain/entities/invite_employee_input.dart';
import '../../domain/entities/update_employee_input.dart';
import '../../domain/entities/update_my_profile_input.dart';
import '../models/employee_model.dart';

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
}
