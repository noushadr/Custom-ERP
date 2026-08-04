import '../entities/auth_user.dart';

abstract interface class AuthRepository {
  /// Throws [AuthException] on invalid credentials or network failure.
  Future<AuthUser> login(String email, String password);

  Future<void> logout();

  /// Returns null if there is no valid session to restore.
  Future<AuthUser?> getCurrentUser();
}
