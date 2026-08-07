import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/exceptions/auth_exception.dart';
import '../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthInitial());

  final AuthRepository _repository;

  Future<void> restoreSession() async {
    state = const AuthLoading();
    final user = await _repository.getCurrentUser();
    state = user != null
        ? AuthAuthenticated(user)
        : const AuthUnauthenticated();
  }

  Future<void> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repository.login(
        email,
        password,
        rememberMe: rememberMe,
      );
      state = AuthAuthenticated(user);
    } on AuthException catch (error) {
      state = AuthUnauthenticated(errorMessage: error.message);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthUnauthenticated();
  }

  /// Switches the active session to [userId]. Throws [AuthException] on
  /// failure, leaving the current session untouched.
  Future<void> impersonate(String userId) async {
    final current = state;
    if (current is! AuthAuthenticated) return;

    final targetUser = await _repository.impersonate(userId);
    state = AuthAuthenticated(
      targetUser,
      impersonatedBy: current.impersonatedBy ?? current.user,
    );
  }

  Future<void> returnToAdmin() async {
    final admin = await _repository.returnToAdmin();
    state = admin != null
        ? AuthAuthenticated(admin)
        : const AuthUnauthenticated();
  }

  /// Sets a new temporary password for [userId]. Doesn't affect the current
  /// session/state — just a passthrough so callers don't need direct access
  /// to the repository. Throws [AuthException] on failure.
  Future<String> resetPassword(String userId) =>
      _repository.resetPassword(userId);

  /// Changes the current user's own password. Throws [AuthException] on
  /// failure. Doesn't affect the current session/state.
  Future<void> changePassword(String currentPassword, String newPassword) =>
      _repository.changePassword(currentPassword, newPassword);
}
