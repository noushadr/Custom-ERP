import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/update_employee_input.dart';
import '../domain/exceptions/employee_exception.dart';
import '../domain/repositories/employee_repository.dart';
import 'edit_employee_state.dart';
import 'employee_providers.dart';

class EditEmployeeController extends StateNotifier<EditEmployeeState> {
  EditEmployeeController(this._repository) : super(const EditEmployeeIdle());

  final EmployeeRepository _repository;

  Future<void> submit(String employeeId, UpdateEmployeeInput input) async {
    state = const EditEmployeeSubmitting();
    try {
      final employee = await _repository.updateEmployee(employeeId, input);
      state = EditEmployeeSuccess(employee);
    } on EmployeeException catch (error) {
      state = EditEmployeeError(error.message);
    }
  }
}

final editEmployeeControllerProvider =
    StateNotifierProvider.autoDispose<EditEmployeeController, EditEmployeeState>(
      (ref) => EditEmployeeController(ref.watch(employeeRepositoryProvider)),
    );
