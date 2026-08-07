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

  /// Switches the active session to [userId] without their password.
  /// Requires `users.impersonate` (Super Admin only) on the current session.
  /// Throws [AuthException] on failure. Stashes the current session so
  /// [returnToAdmin] can restore it.
  Future<AuthUser> impersonate(String userId);

  /// Restores the session stashed by [impersonate]. Returns null if there
  /// was nothing to restore or the stashed session is no longer valid.
  Future<AuthUser?> returnToAdmin();

  /// Sets a new temporary password for [userId] and returns it, so it can be
  /// shared with them directly — there is no email delivery yet, same as
  /// the invite flow. Requires `users.manage` (Super Admin or HR/Manager).
  /// Throws [AuthException] on failure.
  Future<String> resetPassword(String userId);

  /// Changes the current user's own password. Requires the correct current
  /// password, unlike [resetPassword] which is HR-initiated.
  /// Throws [AuthException] on failure.
  Future<void> changePassword(String currentPassword, String newPassword);
}
