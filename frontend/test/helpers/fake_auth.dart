import 'package:zera_erp/features/authentication/application/auth_controller.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/authentication/domain/repositories/auth_repository.dart';

const testAuthUser = AuthUser(
  id: 'user-1',
  email: 'jane.doe@zeracreative.com',
  role: 'Employee',
  permissions: [],
);

/// Repository test double with no real network/storage calls. Configure
/// [loginResult] or [loginError] to control what `login()` does.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.loginResult, this.loginError});

  final AuthUser? loginResult;
  final Object? loginError;

  @override
  Future<AuthUser> login(String email, String password) async {
    if (loginError != null) throw loginError!;
    return loginResult ?? testAuthUser;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthUser?> getCurrentUser() async => null;
}

/// An [AuthController] whose state can be preset directly, bypassing session
/// restoration — for tests that only care about a specific already-settled
/// state (e.g. the authenticated shell).
class PresetAuthController extends AuthController {
  PresetAuthController(AuthState initial, {AuthRepository? repository})
    : super(repository ?? FakeAuthRepository()) {
    state = initial;
  }
}
