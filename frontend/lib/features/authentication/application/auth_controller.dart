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

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final user = await _repository.login(email, password);
      state = AuthAuthenticated(user);
    } on AuthException catch (error) {
      state = AuthUnauthenticated(errorMessage: error.message);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthUnauthenticated();
  }
}
