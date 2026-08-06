import 'dart:typed_data';
import '../../../../shared/models/named_ref.dart';
import '../entities/employee.dart';
import '../entities/employee_document.dart';
import '../entities/invite_employee_input.dart';
import '../entities/update_employee_input.dart';
import '../entities/update_my_profile_input.dart';

abstract interface class EmployeeRepository {
  /// Throws [EmployeeException] on failure.
  Future<List<Employee>> getAll();

  Future<Employee> getById(String id);

  Future<Employee> getMe();

  Future<Employee> updateMe(UpdateMyProfileInput input);

  /// Requires `employees.manage`.
  Future<Employee> updateEmployee(String id, UpdateEmployeeInput input);

  Future<Employee> uploadMyPhoto(Uint8List bytes, String fileName);

  Future<({Employee employee, String temporaryPassword})> invite(
    InviteEmployeeInput input,
  );

  Future<List<NamedRef>> getDepartments();

  Future<List<NamedRef>> getTeams({String? departmentId});

  Future<List<EmployeeDocument>> getMyDocuments();

  Future<EmployeeDocument> uploadMyDocument(Uint8List bytes, String fileName);

  Future<void> deleteMyDocument(String documentId);

  /// Requires `employees.manage`.
  Future<List<EmployeeDocument>> getDocuments(String employeeId);

  /// Requires `employees.manage`.
  Future<EmployeeDocument> uploadDocument(
    String employeeId,
    Uint8List bytes,
    String fileName,
  );

  /// Requires `employees.manage`.
  Future<void> deleteDocument(String employeeId, String documentId);
}
