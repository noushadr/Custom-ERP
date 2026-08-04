import 'package:dio/dio.dart';
import '../../../../core/network/token_storage.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource, this._tokenStorage);

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  @override
  Future<AuthUser> login(String email, String password) async {
    try {
      final result = await _remoteDataSource.login(email, password);
      await _tokenStorage.saveTokens(
        accessToken: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken,
      );
      return result.user;
    } on DioException catch (error) {
      throw AuthException(_mapLoginError(error));
    }
  }

  @override
  Future<void> logout() => _tokenStorage.clear();

  @override
  Future<AuthUser?> getCurrentUser() async {
    final token = await _tokenStorage.accessToken;
    if (token == null) return null;

    try {
      return await _remoteDataSource.me();
    } on DioException {
      // The client already attempted a token refresh; a failure here means
      // the session is no longer valid.
      await _tokenStorage.clear();
      return null;
    }
  }

  String _mapLoginError(DioException error) {
    if (error.response?.statusCode == 401) {
      return 'Invalid email or password.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
