import '../domain/entities/employee.dart';

sealed class EditEmployeeState {
  const EditEmployeeState();
}

class EditEmployeeIdle extends EditEmployeeState {
  const EditEmployeeIdle();
}

class EditEmployeeSubmitting extends EditEmployeeState {
  const EditEmployeeSubmitting();
}

class EditEmployeeSuccess extends EditEmployeeState {
  const EditEmployeeSuccess(this.employee);

  final Employee employee;
}

class EditEmployeeError extends EditEmployeeState {
  const EditEmployeeError(this.message);

  final String message;
}
