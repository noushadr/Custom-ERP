import 'dart:typed_data';
import '../../../../shared/models/named_ref.dart';
import '../entities/employee.dart';
import '../entities/invite_employee_input.dart';
import '../entities/update_my_profile_input.dart';

abstract interface class EmployeeRepository {
  /// Throws [EmployeeException] on failure.
  Future<List<Employee>> getAll();

  Future<Employee> getById(String id);

  Future<Employee> getMe();

  Future<Employee> updateMe(UpdateMyProfileInput input);

  Future<Employee> uploadMyPhoto(Uint8List bytes, String fileName);

  Future<({Employee employee, String temporaryPassword})> invite(
    InviteEmployeeInput input,
  );

  Future<List<NamedRef>> getDepartments();

  Future<List<NamedRef>> getTeams({String? departmentId});
}
