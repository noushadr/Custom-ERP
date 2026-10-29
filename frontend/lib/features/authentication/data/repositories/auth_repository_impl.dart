import 'package:dio/dio.dart';
import '../../../../core/network/token_storage.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(
    this._remoteDataSource,
    this._tokenStorage, {
    this.restoreRetryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ],
  });

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  /// Waits between attempts to confirm a saved session on startup when the
  /// server can't be reached (e.g. it is restarting for a deploy).
  final List<Duration> restoreRetryDelays;

  @override
  Future<AuthUser> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    try {
      final result = await _remoteDataSource.login(email, password);
      await _tokenStorage.saveTokens(
        accessToken: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken,
        rememberMe: rememberMe,
      );
      return result.user;
    } on DioException catch (error) {
      throw AuthException(_mapLoginError(error));
    }
  }

  @override
  Future<void> logout() => _tokenStorage.clear();

  @override
  Future<AuthUser> impersonate(String userId) async {
    try {
      _tokenStorage.stashCurrentSession();
      final result = await _remoteDataSource.impersonate(userId);
      await _tokenStorage.saveTokens(
        accessToken: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken,
        // Never persisted: an impersonated session should never silently
        // survive an app restart.
        rememberMe: false,
      );
      return result.user;
    } on DioException catch (error) {
      throw AuthException(_mapImpersonateError(error));
    }
  }

  @override
  Future<AuthUser?> returnToAdmin() async {
    if (!_tokenStorage.hasStashedSession) return null;
    await _tokenStorage.restoreStashedSession();
    try {
      return await _remoteDataSource.me();
    } on DioException {
      await _tokenStorage.clear();
      return null;
    }
  }

  @override
  Future<String> resetPassword(String userId) async {
    try {
      return await _remoteDataSource.resetPassword(userId);
    } on DioException catch (error) {
      throw AuthException(_mapResetPasswordError(error));
    }
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await _remoteDataSource.changePassword(currentPassword, newPassword);
    } on DioException catch (error) {
      throw AuthException(_mapChangePasswordError(error));
    }
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    final token = await _tokenStorage.accessToken;
    if (token == null) return null;

    for (var attempt = 0; ; attempt++) {
      try {
        return await _remoteDataSource.me();
      } on DioException catch (error) {
        // The client already attempted a token refresh. Only the server
        // rejecting the credentials means the session is really over — a
        // network blip, timeout, rate limit (429) or 5xx (e.g. the backend
        // restarting during a deploy) says nothing about it, and wiping the
        // saved login on one of those signed people out over a hiccup.
        final status = error.response?.statusCode;
        if (status == 401 || status == 403) {
          await _tokenStorage.clear();
          return null;
        }
        if (attempt >= restoreRetryDelays.length) {
          // Still can't tell: keep the saved tokens so the next reload
          // restores the session, and show the login screen for now.
          return null;
        }
        await Future<void>.delayed(restoreRetryDelays[attempt]);
      }
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

  String _mapImpersonateError(DioException error) {
    final status = error.response?.statusCode;
    if (status == 403) return "You don't have permission to do that.";
    if (status == 404) return 'That user could not be found.';
    if (status == 400) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'That account cannot be signed in as.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }

  String _mapResetPasswordError(DioException error) {
    final status = error.response?.statusCode;
    if (status == 403) return "You don't have permission to do that.";
    if (status == 404) return 'That user could not be found.';
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }

  String _mapChangePasswordError(DioException error) {
    final status = error.response?.statusCode;
    if (status == 400) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'Could not change your password.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
