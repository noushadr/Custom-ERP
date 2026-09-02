import 'package:zera_erp/features/performance_reviews/domain/entities/performance_review.dart';
import 'package:zera_erp/features/performance_reviews/domain/entities/performance_review_criterion.dart';
import 'package:zera_erp/features/performance_reviews/domain/entities/performance_review_response.dart';
import 'package:zera_erp/features/performance_reviews/domain/entities/performance_review_response_input.dart';
import 'package:zera_erp/features/performance_reviews/domain/entities/performance_review_summary.dart';
import 'package:zera_erp/features/performance_reviews/domain/repositories/performance_review_repository.dart';

PerformanceReviewSummary buildTestPerformanceReviewSummary({
  String employeeId = 'employee-1',
  int reviewYear = 1,
  String dueDate = '2026-01-01',
  String status = 'pending',
  DateTime? completedAt,
  DateTime? finalizedAt,
}) {
  return PerformanceReviewSummary(
    employeeId: employeeId,
    reviewYear: reviewYear,
    dueDate: dueDate,
    status: status,
    completedAt: completedAt,
    finalizedAt: finalizedAt,
  );
}

PerformanceReviewCriterion buildTestPerformanceReviewCriterion({
  String id = 'criterion-1',
  String name = 'Overall Performance',
  String responseType = 'rating',
  int sortOrder = 0,
  bool isArchived = false,
}) {
  return PerformanceReviewCriterion(
    id: id,
    name: name,
    responseType: responseType,
    sortOrder: sortOrder,
    isArchived: isArchived,
  );
}

PerformanceReviewResponse buildTestPerformanceReviewResponse({
  String id = 'response-1',
  String? criterionId = 'criterion-1',
  String criterionName = 'Overall Performance',
  String responseType = 'rating',
  int sortOrder = 0,
  int? ratingValue,
  String? textValue,
}) {
  return PerformanceReviewResponse(
    id: id,
    criterionId: criterionId,
    criterionName: criterionName,
    responseType: responseType,
    sortOrder: sortOrder,
    ratingValue: ratingValue,
    textValue: textValue,
  );
}

PerformanceReview buildTestPerformanceReview({
  String id = 'review-1',
  String employeeId = 'employee-1',
  String employeeName = 'Jane Doe',
  String? employeePhotoUrl,
  int reviewYear = 1,
  String dueDate = '2026-01-01',
  String status = 'pending',
  List<PerformanceReviewResponse>? responses,
  String? employeeComments,
  String? completedByName,
  DateTime? completedAt,
  bool? completedAsManager,
  String? finalizedByName,
  DateTime? finalizedAt,
  DateTime? createdAt,
}) {
  return PerformanceReview(
    id: id,
    employeeId: employeeId,
    employeeName: employeeName,
    employeePhotoUrl: employeePhotoUrl,
    reviewYear: reviewYear,
    dueDate: dueDate,
    status: status,
    responses: responses ?? [buildTestPerformanceReviewResponse()],
    employeeComments: employeeComments,
    completedByName: completedByName,
    completedAt: completedAt,
    completedAsManager: completedAsManager,
    finalizedByName: finalizedByName,
    finalizedAt: finalizedAt,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}

class FakePerformanceReviewRepository implements PerformanceReviewRepository {
  FakePerformanceReviewRepository({
    this.criteria = const [],
    this.myReviews = const [],
    this.pendingManagerAction = const [],
    this.pendingHrFinalization = const [],
    this.employeeReviews = const [],
    this.latestReviewSummaries = const [],
    this.latestForMyTeam = const [],
    this.allPendingReviews = const [],
    this.pendingReviewsDelta = 0,
    this.finalizedReviews = const [],
    this.reviewById,
    this.dueCheckPreview = const [],
    this.dueCheckCreatedCount = 0,
    this.createCriterionError,
    this.updateCriterionError,
    this.reorderCriteriaError,
    this.deleteCriterionError,
    this.createManualReviewError,
    this.completeReviewError,
    this.setSelfAssessmentError,
    this.finalizeReviewError,
    this.unfinalizeReviewError,
    this.adminUpdateReviewError,
  });

  final List<PerformanceReviewCriterion> criteria;
  final List<PerformanceReview> myReviews;
  final List<PerformanceReview> pendingManagerAction;
  final List<PerformanceReview> pendingHrFinalization;
  final List<PerformanceReview> employeeReviews;
  final List<PerformanceReviewSummary> latestReviewSummaries;
  final List<PerformanceReviewSummary> latestForMyTeam;
  final List<PerformanceReview> allPendingReviews;
  final int pendingReviewsDelta;
  final List<PerformanceReview> finalizedReviews;
  final PerformanceReview? reviewById;
  final List<Map<String, dynamic>> dueCheckPreview;
  final int dueCheckCreatedCount;

  final Object? createCriterionError;
  final Object? updateCriterionError;
  final Object? reorderCriteriaError;
  final Object? deleteCriterionError;
  final Object? createManualReviewError;
  final Object? completeReviewError;
  final Object? setSelfAssessmentError;
  final Object? finalizeReviewError;
  final Object? unfinalizeReviewError;
  final Object? adminUpdateReviewError;

  List<String>? lastReorderedIds;
  String? lastDeletedCriterionId;
  String? lastCompletedReviewId;
  List<PerformanceReviewResponseInput>? lastCompletedResponses;
  String? lastSelfAssessmentReviewId;
  String? lastSelfAssessmentComments;
  String? lastFinalizedReviewId;
  String? lastUnfinalizedReviewId;

  @override
  Future<List<PerformanceReviewCriterion>> getCriteria({
    bool includeArchived = false,
  }) async => criteria;

  @override
  Future<PerformanceReviewCriterion> createCriterion({
    required String name,
    required String responseType,
  }) async {
    if (createCriterionError != null) throw createCriterionError!;
    return buildTestPerformanceReviewCriterion(
      name: name,
      responseType: responseType,
    );
  }

  @override
  Future<PerformanceReviewCriterion> updateCriterion(
    String id, {
    String? name,
    String? responseType,
    bool? isArchived,
  }) async {
    if (updateCriterionError != null) throw updateCriterionError!;
    return buildTestPerformanceReviewCriterion(
      id: id,
      name: name ?? 'Overall Performance',
      responseType: responseType ?? 'rating',
      isArchived: isArchived ?? false,
    );
  }

  @override
  Future<List<PerformanceReviewCriterion>> reorderCriteria(
    List<String> orderedIds,
  ) async {
    lastReorderedIds = orderedIds;
    if (reorderCriteriaError != null) throw reorderCriteriaError!;
    return criteria;
  }

  @override
  Future<void> deleteCriterion(String id) async {
    lastDeletedCriterionId = id;
    if (deleteCriterionError != null) throw deleteCriterionError!;
  }

  @override
  Future<List<PerformanceReview>> getMyReviews() async => myReviews;

  @override
  Future<PerformanceReview> getReview(String id) async =>
      reviewById ?? buildTestPerformanceReview(id: id);

  @override
  Future<List<PerformanceReview>> getPendingManagerAction() async =>
      pendingManagerAction;

  @override
  Future<List<PerformanceReview>> getPendingHrFinalization() async =>
      pendingHrFinalization;

  @override
  Future<List<PerformanceReview>> getEmployeeReviews(String employeeId) async =>
      employeeReviews;

  @override
  Future<List<PerformanceReviewSummary>> getLatestReviewSummaries() async =>
      latestReviewSummaries;

  @override
  Future<List<PerformanceReviewSummary>> getLatestForMyTeam() async =>
      latestForMyTeam;

  @override
  Future<List<PerformanceReview>> getAllPendingReviews() async =>
      allPendingReviews;

  @override
  Future<int> getPendingReviewsDelta({int days = 7}) async =>
      pendingReviewsDelta;

  @override
  Future<List<PerformanceReview>> getFinalizedReviews() async =>
      finalizedReviews;

  @override
  Future<List<Map<String, dynamic>>> previewDueCheck() async => dueCheckPreview;

  @override
  Future<int> runDueCheck() async => dueCheckCreatedCount;

  @override
  Future<PerformanceReview> createManualReview({
    required String employeeId,
    required int reviewYear,
  }) async {
    if (createManualReviewError != null) throw createManualReviewError!;
    return buildTestPerformanceReview(
      employeeId: employeeId,
      reviewYear: reviewYear,
    );
  }

  @override
  Future<PerformanceReview> completeReview(
    String id, {
    required List<PerformanceReviewResponseInput> responses,
  }) async {
    lastCompletedReviewId = id;
    lastCompletedResponses = responses;
    if (completeReviewError != null) throw completeReviewError!;
    return reviewById ?? buildTestPerformanceReview(id: id, status: 'completed');
  }

  @override
  Future<PerformanceReview> setSelfAssessment(String id, String comments) async {
    lastSelfAssessmentReviewId = id;
    lastSelfAssessmentComments = comments;
    if (setSelfAssessmentError != null) throw setSelfAssessmentError!;
    return reviewById ??
        buildTestPerformanceReview(id: id, employeeComments: comments);
  }

  @override
  Future<PerformanceReview> finalizeReview(String id) async {
    lastFinalizedReviewId = id;
    if (finalizeReviewError != null) throw finalizeReviewError!;
    return reviewById ?? buildTestPerformanceReview(id: id, status: 'finalized');
  }

  @override
  Future<PerformanceReview> unfinalizeReview(String id) async {
    lastUnfinalizedReviewId = id;
    if (unfinalizeReviewError != null) throw unfinalizeReviewError!;
    return reviewById ?? buildTestPerformanceReview(id: id, status: 'completed');
  }

  @override
  Future<PerformanceReview> adminUpdateReview(
    String id, {
    String? employeeComments,
    List<PerformanceReviewResponseInput>? responses,
  }) async {
    if (adminUpdateReviewError != null) throw adminUpdateReviewError!;
    return reviewById ?? buildTestPerformanceReview(id: id);
  }
}
