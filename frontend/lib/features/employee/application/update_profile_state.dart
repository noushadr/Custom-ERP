import '../domain/entities/employee.dart';

sealed class UpdateProfileState {
  const UpdateProfileState();
}

class UpdateProfileIdle extends UpdateProfileState {
  const UpdateProfileIdle();
}

class UpdateProfileSubmitting extends UpdateProfileState {
  const UpdateProfileSubmitting();
}

class UpdateProfileSuccess extends UpdateProfileState {
  const UpdateProfileSuccess(this.employee);

  final Employee employee;
}

class UpdateProfileError extends UpdateProfileState {
  const UpdateProfileError(this.message);

  final String message;
}
