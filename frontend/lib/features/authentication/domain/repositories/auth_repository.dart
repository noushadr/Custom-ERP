import '../entities/auth_user.dart';

abstract interface class AuthRepository {
  /// Throws [AuthException] on invalid credentials or network failure.
  ///
  /// When [rememberMe] is false, the session still works normally until the
  /// app closes, but won't be restored on the next launch.
  Future<AuthUser> login(
    String email,
    String password, {
    bool rememberMe = true,
  });

  Future<void> logout();

  /// Returns null if there is no valid session to restore.
  Future<AuthUser?> getCurrentUser();
}
