import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/update_my_profile_input.dart';
import '../domain/exceptions/employee_exception.dart';
import '../domain/repositories/employee_repository.dart';
import 'employee_providers.dart';
import 'update_profile_state.dart';

class UpdateProfileController extends StateNotifier<UpdateProfileState> {
  UpdateProfileController(this._repository) : super(const UpdateProfileIdle());

  final EmployeeRepository _repository;

  Future<void> submit(UpdateMyProfileInput input) async {
    state = const UpdateProfileSubmitting();
    try {
      final employee = await _repository.updateMe(input);
      state = UpdateProfileSuccess(employee);
    } on EmployeeException catch (error) {
      state = UpdateProfileError(error.message);
    }
  }
}

final updateProfileControllerProvider =
    StateNotifierProvider.autoDispose<UpdateProfileController, UpdateProfileState>(
      (ref) => UpdateProfileController(ref.watch(employeeRepositoryProvider)),
    );
