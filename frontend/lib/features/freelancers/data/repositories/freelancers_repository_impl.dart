import 'package:dio/dio.dart';
import '../../domain/entities/freelancer.dart';
import '../../domain/exceptions/freelancer_exception.dart';
import '../../domain/repositories/freelancers_repository.dart';
import '../datasources/freelancers_remote_data_source.dart';

class FreelancersRepositoryImpl implements FreelancersRepository {
  const FreelancersRepositoryImpl(this._remoteDataSource);

  final FreelancersRemoteDataSource _remoteDataSource;

  @override
  Future<List<Freelancer>> getFreelancers({bool activeOnly = false}) =>
      _guard(() => _remoteDataSource.getFreelancers(activeOnly: activeOnly));

  @override
  Future<Freelancer> createFreelancer({
    required String fullName,
    String? role,
    String? notes,
  }) => _guard(
    () => _remoteDataSource.createFreelancer(
      fullName: fullName,
      role: role,
      notes: notes,
    ),
  );

  @override
  Future<Freelancer> updateFreelancer(
    String id, {
    String? fullName,
    String? role,
    String? notes,
    bool? isActive,
  }) => _guard(
    () => _remoteDataSource.updateFreelancer(
      id,
      fullName: fullName,
      role: role,
      notes: notes,
      isActive: isActive,
    ),
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw FreelancerException(_mapError(error));
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
    if (status == 404) return 'That could not be found.';
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
