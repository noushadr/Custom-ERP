import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/add_employee_input.dart';
import '../domain/exceptions/employee_exception.dart';
import '../domain/repositories/employee_repository.dart';
import 'employee_providers.dart';
import 'add_employee_state.dart';

class AddEmployeeController extends StateNotifier<AddEmployeeState> {
  AddEmployeeController(this._repository) : super(const AddEmployeeIdle());

  final EmployeeRepository _repository;

  Future<void> submit(AddEmployeeInput input) async {
    state = const AddEmployeeSubmitting();
    try {
      final employee = await _repository.addEmployee(input);
      state = AddEmployeeSuccess(employee);
    } on EmployeeException catch (error) {
      state = AddEmployeeError(error.message);
    }
  }

  void reset() => state = const AddEmployeeIdle();
}

final addEmployeeControllerProvider =
    StateNotifierProvider.autoDispose<AddEmployeeController, AddEmployeeState>(
      (ref) => AddEmployeeController(ref.watch(employeeRepositoryProvider)),
    );
