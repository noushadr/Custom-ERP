import 'package:dio/dio.dart';
import '../../domain/entities/permission.dart';
import '../../domain/entities/role.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/repositories/role_repository.dart';
import '../datasources/role_remote_data_source.dart';

class RoleRepositoryImpl implements RoleRepository {
  const RoleRepositoryImpl(this._remoteDataSource);

  final RoleRemoteDataSource _remoteDataSource;

  @override
  Future<List<Role>> getRoles() => _guard(() => _remoteDataSource.getRoles());

  @override
  Future<List<Permission>> getPermissions() =>
      _guard(() => _remoteDataSource.getPermissions());

  @override
  Future<Role> createRole({
    required String name,
    String? description,
    required List<String> permissionKeys,
  }) => _guard(
    () => _remoteDataSource.createRole(
      name: name,
      description: description,
      permissionKeys: permissionKeys,
    ),
  );

  @override
  Future<Role> updateRole(
    String id, {
    String? name,
    String? description,
    List<String>? permissionKeys,
  }) => _guard(
    () => _remoteDataSource.updateRole(
      id,
      name: name,
      description: description,
      permissionKeys: permissionKeys,
    ),
  );

  @override
  Future<void> deleteRole(String id) =>
      _guard(() => _remoteDataSource.deleteRole(id));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw AuthException(_mapError(error));
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
    if (status == 404) return 'That could not be found.';
    if (status == 409) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'That conflicts with existing data.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
