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
  FakeAuthRepository({
    this.loginResult,
    this.loginError,
    this.impersonateResult,
    this.impersonateError,
    this.returnToAdminResult,
    this.resetPasswordResult,
    this.resetPasswordError,
    this.changePasswordError,
  });

  final AuthUser? loginResult;
  final Object? loginError;
  final AuthUser? impersonateResult;
  final Object? impersonateError;
  final AuthUser? returnToAdminResult;
  final String? resetPasswordResult;
  final Object? resetPasswordError;
  final Object? changePasswordError;

  /// The `rememberMe` value passed to the most recent [login] call.
  bool? lastRememberMe;

  /// The `userId` passed to the most recent [impersonate] call.
  String? lastImpersonatedUserId;

  /// The `userId` passed to the most recent [resetPassword] call.
  String? lastResetPasswordUserId;

  /// The new password passed to the most recent [changePassword] call.
  String? lastChangePasswordNewPassword;

  @override
  Future<AuthUser> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    lastRememberMe = rememberMe;
    if (loginError != null) throw loginError!;
    return loginResult ?? testAuthUser;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthUser?> getCurrentUser() async => null;

  @override
  Future<AuthUser> impersonate(String userId) async {
    lastImpersonatedUserId = userId;
    if (impersonateError != null) throw impersonateError!;
    return impersonateResult ?? testAuthUser;
  }

  @override
  Future<AuthUser?> returnToAdmin() async => returnToAdminResult;

  @override
  Future<String> resetPassword(String userId) async {
    lastResetPasswordUserId = userId;
    if (resetPasswordError != null) throw resetPasswordError!;
    return resetPasswordResult ?? 'Temp1234pass';
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    lastChangePasswordNewPassword = newPassword;
    if (changePasswordError != null) throw changePasswordError!;
  }
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
