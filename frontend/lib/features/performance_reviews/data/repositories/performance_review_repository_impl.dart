import 'package:dio/dio.dart';
import '../../domain/entities/performance_review.dart';
import '../../domain/entities/performance_review_criterion.dart';
import '../../domain/entities/performance_review_response_input.dart';
import '../../domain/entities/performance_review_summary.dart';
import '../../domain/exceptions/performance_review_exception.dart';
import '../../domain/repositories/performance_review_repository.dart';
import '../datasources/performance_review_remote_data_source.dart';

class PerformanceReviewRepositoryImpl implements PerformanceReviewRepository {
  const PerformanceReviewRepositoryImpl(this._remoteDataSource);

  final PerformanceReviewRemoteDataSource _remoteDataSource;

  @override
  Future<List<PerformanceReviewCriterion>> getCriteria({
    bool includeArchived = false,
  }) => _guard(
    () => _remoteDataSource.getCriteria(includeArchived: includeArchived),
  );

  @override
  Future<PerformanceReviewCriterion> createCriterion({
    required String name,
    required String responseType,
  }) => _guard(
    () => _remoteDataSource.createCriterion(
      name: name,
      responseType: responseType,
    ),
  );

  @override
  Future<PerformanceReviewCriterion> updateCriterion(
    String id, {
    String? name,
    String? responseType,
    bool? isArchived,
  }) => _guard(
    () => _remoteDataSource.updateCriterion(
      id,
      name: name,
      responseType: responseType,
      isArchived: isArchived,
    ),
  );

  @override
  Future<List<PerformanceReviewCriterion>> reorderCriteria(
    List<String> orderedIds,
  ) => _guard(() => _remoteDataSource.reorderCriteria(orderedIds));

  @override
  Future<void> deleteCriterion(String id) =>
      _guard(() => _remoteDataSource.deleteCriterion(id));

  @override
  Future<List<PerformanceReview>> getMyReviews() =>
      _guard(() => _remoteDataSource.getMyReviews());

  @override
  Future<PerformanceReview> getReview(String id) =>
      _guard(() => _remoteDataSource.getReview(id));

  @override
  Future<List<PerformanceReview>> getPendingManagerAction() =>
      _guard(() => _remoteDataSource.getPendingManagerAction());

  @override
  Future<List<PerformanceReview>> getPendingHrFinalization() =>
      _guard(() => _remoteDataSource.getPendingHrFinalization());

  @override
  Future<List<PerformanceReview>> getEmployeeReviews(String employeeId) =>
      _guard(() => _remoteDataSource.getEmployeeReviews(employeeId));

  @override
  Future<List<PerformanceReview>> getAllPendingReviews() =>
      _guard(() => _remoteDataSource.getAllPendingReviews());

  @override
  Future<List<PerformanceReview>> getFinalizedReviews() =>
      _guard(() => _remoteDataSource.getFinalizedReviews());

  @override
  Future<List<PerformanceReviewSummary>> getLatestReviewSummaries() =>
      _guard(() => _remoteDataSource.getLatestReviewSummaries());

  @override
  Future<List<Map<String, dynamic>>> previewDueCheck() =>
      _guard(() => _remoteDataSource.previewDueCheck());

  @override
  Future<int> runDueCheck() => _guard(() => _remoteDataSource.runDueCheck());

  @override
  Future<PerformanceReview> createManualReview({
    required String employeeId,
    required int reviewYear,
  }) => _guard(
    () => _remoteDataSource.createManualReview(
      employeeId: employeeId,
      reviewYear: reviewYear,
    ),
  );

  @override
  Future<PerformanceReview> completeReview(
    String id, {
    required List<PerformanceReviewResponseInput> responses,
  }) => _guard(
    () => _remoteDataSource.completeReview(id, responses: responses),
  );

  @override
  Future<PerformanceReview> setSelfAssessment(String id, String comments) =>
      _guard(() => _remoteDataSource.setSelfAssessment(id, comments));

  @override
  Future<PerformanceReview> finalizeReview(String id) =>
      _guard(() => _remoteDataSource.finalizeReview(id));

  @override
  Future<PerformanceReview> adminUpdateReview(
    String id, {
    String? employeeComments,
    List<PerformanceReviewResponseInput>? responses,
  }) => _guard(
    () => _remoteDataSource.adminUpdateReview(
      id,
      employeeComments: employeeComments,
      responses: responses,
    ),
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw PerformanceReviewException(_mapError(error));
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
    if (status == 409) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'This conflicts with existing data.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
