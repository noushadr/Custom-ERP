import 'package:dio/dio.dart';
import '../models/permission_model.dart';
import '../models/role_model.dart';

class RoleRemoteDataSource {
  const RoleRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<RoleModel>> getRoles() async {
    final response = await _dio.get<List<dynamic>>('/roles');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(RoleModel.fromJson)
        .toList();
  }

  Future<List<PermissionModel>> getPermissions() async {
    final response = await _dio.get<List<dynamic>>('/permissions');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(PermissionModel.fromJson)
        .toList();
  }

  Future<RoleModel> createRole({
    required String name,
    String? description,
    required List<String> permissionKeys,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/roles',
      data: {
        'name': name,
        'description': description,
        'permissionKeys': permissionKeys,
      },
    );
    return RoleModel.fromJson(response.data!);
  }

  Future<RoleModel> updateRole(
    String id, {
    String? name,
    String? description,
    List<String>? permissionKeys,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (permissionKeys != null) data['permissionKeys'] = permissionKeys;
    final response = await _dio.patch<Map<String, dynamic>>(
      '/roles/$id',
      data: data,
    );
    return RoleModel.fromJson(response.data!);
  }

  Future<void> deleteRole(String id) async {
    await _dio.delete('/roles/$id');
  }
}
