import 'package:zera_erp/features/employee/domain/entities/employee.dart';
import 'package:zera_erp/features/employee/domain/entities/invite_employee_input.dart';
import 'package:zera_erp/features/employee/domain/entities/update_my_profile_input.dart';
import 'package:zera_erp/features/employee/domain/repositories/employee_repository.dart';
import 'package:zera_erp/shared/models/named_ref.dart';

Employee buildTestEmployee({
  String id = 'employee-1',
  String employeeCode = 'ZC-00001',
  String email = 'jane.doe@zeracreative.com',
  String role = 'Employee',
  String fullName = 'Jane Doe',
  String? designation = 'Software Engineer',
  NamedRef? department,
  int profileCompletionPercentage = 25,
}) {
  final parts = fullName.split(' ');
  return Employee(
    id: id,
    employeeCode: employeeCode,
    email: email,
    role: role,
    accountStatus: 'active',
    firstName: parts.first,
    lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
    fullName: fullName,
    profilePhotoUrl: null,
    designation: designation,
    department: department,
    team: null,
    reportingManager: null,
    employmentType: 'full_time',
    employmentStatus: 'active',
    joiningDate: '2026-01-01',
    personalEmail: null,
    phoneNumber: null,
    emergencyContactName: null,
    emergencyContactPhone: null,
    emergencyContactRelation: null,
    address: null,
    skills: const [],
    certifications: const [],
    profileCompletionPercentage: profileCompletionPercentage,
  );
}

class FakeEmployeeRepository implements EmployeeRepository {
  FakeEmployeeRepository({
    this.employees = const [],
    Employee? me,
    this.departments = const [],
    this.teams = const [],
    this.inviteResult,
    this.inviteError,
    this.updateMeResult,
    this.updateMeError,
  }) : me = me ?? buildTestEmployee();

  final List<Employee> employees;
  final Employee me;
  final List<NamedRef> departments;
  final List<NamedRef> teams;
  final ({Employee employee, String temporaryPassword})? inviteResult;
  final Object? inviteError;
  final Employee? updateMeResult;
  final Object? updateMeError;

  @override
  Future<List<Employee>> getAll() async => employees;

  @override
  Future<Employee> getById(String id) async =>
      employees.firstWhere((e) => e.id == id, orElse: () => me);

  @override
  Future<Employee> getMe() async => me;

  @override
  Future<Employee> updateMe(UpdateMyProfileInput input) async {
    if (updateMeError != null) throw updateMeError!;
    return updateMeResult ?? me;
  }

  @override
  Future<({Employee employee, String temporaryPassword})> invite(
    InviteEmployeeInput input,
  ) async {
    if (inviteError != null) throw inviteError!;
    return inviteResult!;
  }

  @override
  Future<List<NamedRef>> getDepartments() async => departments;

  @override
  Future<List<NamedRef>> getTeams({String? departmentId}) async => teams;
}
