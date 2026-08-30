import 'package:dio/dio.dart';
import '../../domain/entities/performance_review_response_input.dart';
import '../models/performance_review_criterion_model.dart';
import '../models/performance_review_model.dart';
import '../models/performance_review_summary_model.dart';

class PerformanceReviewRemoteDataSource {
  const PerformanceReviewRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<PerformanceReviewCriterionModel>> getCriteria({
    bool includeArchived = false,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/performance-reviews/criteria',
      queryParameters: {'includeArchived': includeArchived.toString()},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(PerformanceReviewCriterionModel.fromJson)
        .toList();
  }

  Future<PerformanceReviewCriterionModel> createCriterion({
    required String name,
    required String responseType,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/performance-reviews/criteria',
      data: {'name': name, 'responseType': responseType},
    );
    return PerformanceReviewCriterionModel.fromJson(response.data!);
  }

  Future<PerformanceReviewCriterionModel> updateCriterion(
    String id, {
    String? name,
    String? responseType,
    bool? isArchived,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/performance-reviews/criteria/$id',
      data: {
        'name': ?name,
        'responseType': ?responseType,
        'isArchived': ?isArchived,
      },
    );
    return PerformanceReviewCriterionModel.fromJson(response.data!);
  }

  Future<List<PerformanceReviewCriterionModel>> reorderCriteria(
    List<String> orderedIds,
  ) async {
    final response = await _dio.patch<List<dynamic>>(
      '/performance-reviews/criteria/reorder',
      data: {'orderedIds': orderedIds},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(PerformanceReviewCriterionModel.fromJson)
        .toList();
  }

  Future<void> deleteCriterion(String id) async {
    await _dio.delete('/performance-reviews/criteria/$id');
  }

  Future<List<PerformanceReviewModel>> getMyReviews() async {
    final response = await _dio.get<List<dynamic>>('/performance-reviews/me');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(PerformanceReviewModel.fromJson)
        .toList();
  }

  Future<PerformanceReviewModel> getReview(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/performance-reviews/$id',
    );
    return PerformanceReviewModel.fromJson(response.data!);
  }

  Future<List<PerformanceReviewModel>> getPendingManagerAction() async {
    final response = await _dio.get<List<dynamic>>(
      '/performance-reviews/pending-manager-action',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(PerformanceReviewModel.fromJson)
        .toList();
  }

  Future<List<PerformanceReviewModel>> getPendingHrFinalization() async {
    final response = await _dio.get<List<dynamic>>(
      '/performance-reviews/pending-hr-finalization',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(PerformanceReviewModel.fromJson)
        .toList();
  }

  Future<List<PerformanceReviewModel>> getEmployeeReviews(
    String employeeId,
  ) async {
    final response = await _dio.get<List<dynamic>>(
      '/performance-reviews/employee/$employeeId',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(PerformanceReviewModel.fromJson)
        .toList();
  }

  Future<List<PerformanceReviewModel>> getAllPendingReviews() async {
    final response = await _dio.get<List<dynamic>>(
      '/performance-reviews/pending',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(PerformanceReviewModel.fromJson)
        .toList();
  }

  Future<int> getPendingReviewsDelta({int days = 7}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/performance-reviews/pending-delta',
      queryParameters: {'days': days},
    );
    return response.data!['delta'] as int;
  }

  Future<List<PerformanceReviewModel>> getFinalizedReviews() async {
    final response = await _dio.get<List<dynamic>>(
      '/performance-reviews/finalized',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(PerformanceReviewModel.fromJson)
        .toList();
  }

  Future<List<PerformanceReviewSummaryModel>> getLatestReviewSummaries() async {
    final response = await _dio.get<List<dynamic>>(
      '/performance-reviews/latest-by-employee',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(PerformanceReviewSummaryModel.fromJson)
        .toList();
  }

  Future<List<Map<String, dynamic>>> previewDueCheck() async {
    final response = await _dio.get<List<dynamic>>(
      '/performance-reviews/due-check/preview',
    );
    return response.data!.cast<Map<String, dynamic>>();
  }

  Future<int> runDueCheck() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/performance-reviews/due-check/run',
    );
    return response.data!['created'] as int;
  }

  Future<PerformanceReviewModel> createManualReview({
    required String employeeId,
    required int reviewYear,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/performance-reviews',
      data: {'employeeId': employeeId, 'reviewYear': reviewYear},
    );
    return PerformanceReviewModel.fromJson(response.data!);
  }

  Future<PerformanceReviewModel> completeReview(
    String id, {
    required List<PerformanceReviewResponseInput> responses,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/performance-reviews/$id/complete',
      data: {'responses': responses.map((r) => r.toJson()).toList()},
    );
    return PerformanceReviewModel.fromJson(response.data!);
  }

  Future<PerformanceReviewModel> setSelfAssessment(
    String id,
    String comments,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/performance-reviews/$id/self-assessment',
      data: {'comments': comments},
    );
    return PerformanceReviewModel.fromJson(response.data!);
  }

  Future<PerformanceReviewModel> finalizeReview(String id) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/performance-reviews/$id/finalize',
    );
    return PerformanceReviewModel.fromJson(response.data!);
  }

  Future<PerformanceReviewModel> unfinalizeReview(String id) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/performance-reviews/$id/unfinalize',
    );
    return PerformanceReviewModel.fromJson(response.data!);
  }

  Future<PerformanceReviewModel> adminUpdateReview(
    String id, {
    String? employeeComments,
    List<PerformanceReviewResponseInput>? responses,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/performance-reviews/$id',
      data: {
        'employeeComments': ?employeeComments,
        'responses': ?responses?.map((r) => r.toJson()).toList(),
      },
    );
    return PerformanceReviewModel.fromJson(response.data!);
  }
}
