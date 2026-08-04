import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/invite_employee_input.dart';
import '../domain/exceptions/employee_exception.dart';
import '../domain/repositories/employee_repository.dart';
import 'employee_providers.dart';
import 'invite_employee_state.dart';

class InviteEmployeeController extends StateNotifier<InviteEmployeeState> {
  InviteEmployeeController(this._repository) : super(const InviteIdle());

  final EmployeeRepository _repository;

  Future<void> submit(InviteEmployeeInput input) async {
    state = const InviteSubmitting();
    try {
      final result = await _repository.invite(input);
      state = InviteSuccess(result.employee, result.temporaryPassword);
    } on EmployeeException catch (error) {
      state = InviteError(error.message);
    }
  }

  void reset() => state = const InviteIdle();
}

final inviteEmployeeControllerProvider =
    StateNotifierProvider.autoDispose<InviteEmployeeController, InviteEmployeeState>(
      (ref) => InviteEmployeeController(ref.watch(employeeRepositoryProvider)),
    );
