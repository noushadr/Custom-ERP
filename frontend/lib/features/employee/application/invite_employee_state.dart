import '../domain/entities/employee.dart';

sealed class InviteEmployeeState {
  const InviteEmployeeState();
}

class InviteIdle extends InviteEmployeeState {
  const InviteIdle();
}

class InviteSubmitting extends InviteEmployeeState {
  const InviteSubmitting();
}

class InviteSuccess extends InviteEmployeeState {
  const InviteSuccess(this.employee, this.temporaryPassword);

  final Employee employee;
  final String temporaryPassword;
}

class InviteError extends InviteEmployeeState {
  const InviteError(this.message);

  final String message;
}
