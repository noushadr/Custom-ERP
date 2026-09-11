import '../domain/entities/employee.dart';

sealed class AddEmployeeState {
  const AddEmployeeState();
}

class AddEmployeeIdle extends AddEmployeeState {
  const AddEmployeeIdle();
}

class AddEmployeeSubmitting extends AddEmployeeState {
  const AddEmployeeSubmitting();
}

class AddEmployeeSuccess extends AddEmployeeState {
  const AddEmployeeSuccess(this.employee, this.temporaryPassword);

  final Employee employee;
  final String temporaryPassword;
}

class AddEmployeeError extends AddEmployeeState {
  const AddEmployeeError(this.message);

  final String message;
}
