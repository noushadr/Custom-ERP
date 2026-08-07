import '../domain/entities/auth_user.dart';

sealed class AuthState {
  const AuthState();
}

/// Session restoration from stored tokens hasn't resolved yet.
class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user, {this.impersonatedBy});

  final AuthUser user;

  /// The Super Admin who is logged in as [user], if this session was
  /// started via "Login as". Null for a normal session.
  final AuthUser? impersonatedBy;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.errorMessage});

  final String? errorMessage;
}
