import 'package:dio/dio.dart';
import '../../domain/entities/employee_request.dart';
import '../../domain/exceptions/request_exception.dart';
import '../../domain/repositories/request_repository.dart';
import '../datasources/request_remote_data_source.dart';

class RequestRepositoryImpl implements RequestRepository {
  const RequestRepositoryImpl(this._remoteDataSource);

  final RequestRemoteDataSource _remoteDataSource;

  @override
  Future<EmployeeRequest> submit({
    required String subject,
    required String description,
    String? type,
  }) => _guard(
    () => _remoteDataSource.submit(
      subject: subject,
      description: description,
      type: type,
    ),
  );

  @override
  Future<List<EmployeeRequest>> getMine() =>
      _guard(() => _remoteDataSource.getMine());

  @override
  Future<List<EmployeeRequest>> getPendingManagerApproval() =>
      _guard(() => _remoteDataSource.getPendingManagerApproval());

  @override
  Future<List<EmployeeRequest>> getPendingHrApproval() =>
      _guard(() => _remoteDataSource.getPendingHrApproval());

  @override
  Future<EmployeeRequest> approveAsManager(String requestId) =>
      _guard(() => _remoteDataSource.approveAsManager(requestId));

  @override
  Future<EmployeeRequest> rejectAsManager(String requestId, {String? reason}) =>
      _guard(() => _remoteDataSource.rejectAsManager(requestId, reason: reason));

  @override
  Future<EmployeeRequest> approveAsHr(String requestId) =>
      _guard(() => _remoteDataSource.approveAsHr(requestId));

  @override
  Future<EmployeeRequest> rejectAsHr(String requestId, {String? reason}) =>
      _guard(() => _remoteDataSource.rejectAsHr(requestId, reason: reason));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw RequestException(_mapError(error));
    }
  }

  String _mapError(DioException error) {
    final status = error.response?.statusCode;
    if (status == 400) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'Invalid request.';
    }
    if (status == 403) return "You don't have permission to do that.";
    if (status == 404) return 'That request could not be found.';
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
