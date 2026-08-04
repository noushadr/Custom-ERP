import 'package:dio/dio.dart';
import '../../../../shared/models/named_ref.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/invite_employee_input.dart';
import '../../domain/entities/update_my_profile_input.dart';
import '../../domain/exceptions/employee_exception.dart';
import '../../domain/repositories/employee_repository.dart';
import '../datasources/employee_remote_data_source.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  const EmployeeRepositoryImpl(this._remoteDataSource);

  final EmployeeRemoteDataSource _remoteDataSource;

  @override
  Future<List<Employee>> getAll() =>
      _guard(() => _remoteDataSource.getAll());

  @override
  Future<Employee> getById(String id) =>
      _guard(() => _remoteDataSource.getById(id));

  @override
  Future<Employee> getMe() => _guard(() => _remoteDataSource.getMe());

  @override
  Future<Employee> updateMe(UpdateMyProfileInput input) =>
      _guard(() => _remoteDataSource.updateMe(input));

  @override
  Future<({Employee employee, String temporaryPassword})> invite(
    InviteEmployeeInput input,
  ) => _guard(() => _remoteDataSource.invite(input));

  @override
  Future<List<NamedRef>> getDepartments() =>
      _guard(() => _remoteDataSource.getDepartments());

  @override
  Future<List<NamedRef>> getTeams({String? departmentId}) =>
      _guard(() => _remoteDataSource.getTeams(departmentId: departmentId));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw EmployeeException(_mapError(error));
    }
  }

  String _mapError(DioException error) {
    final status = error.response?.statusCode;
    if (status == 400) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (data is Map && data['message'] is List) {
        return (data['message'] as List).join(', ');
      }
      return 'Invalid request.';
    }
    if (status == 403) return "You don't have permission to do that.";
    if (status == 404) return 'Not found.';
    if (status == 409) return 'A user with this email already exists.';
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
