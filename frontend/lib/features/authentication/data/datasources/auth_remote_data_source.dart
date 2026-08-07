import 'package:dio/dio.dart';
import '../models/auth_tokens_model.dart';
import '../models/auth_user_model.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<({AuthTokensModel tokens, AuthUserModel user})> login(
    String email,
    String password,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = response.data!;
    return (
      tokens: AuthTokensModel.fromJson(data),
      user: AuthUserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<AuthUserModel> me() async {
    final response = await _dio.get<Map<String, dynamic>>('/auth/me');
    return AuthUserModel.fromJson(response.data!);
  }

  Future<({AuthTokensModel tokens, AuthUserModel user})> impersonate(
    String userId,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/impersonate/$userId',
    );
    final data = response.data!;
    return (
      tokens: AuthTokensModel.fromJson(data),
      user: AuthUserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<String> resetPassword(String userId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/users/$userId/reset-password',
    );
    return response.data!['temporaryPassword'] as String;
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await _dio.post<void>(
      '/auth/change-password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }
}
