import '../entities/performance_review.dart';
import '../entities/performance_review_criterion.dart';
import '../entities/performance_review_response_input.dart';
import '../entities/performance_review_summary.dart';

abstract interface class PerformanceReviewRepository {
  Future<List<PerformanceReviewCriterion>> getCriteria({
    bool includeArchived = false,
  });

  /// Requires `performance.manage`.
  Future<PerformanceReviewCriterion> createCriterion({
    required String name,
    required String responseType,
  });

  /// Requires `performance.manage`.
  Future<PerformanceReviewCriterion> updateCriterion(
    String id, {
    String? name,
    String? responseType,
    bool? isArchived,
  });

  /// Requires `performance.manage`.
  Future<List<PerformanceReviewCriterion>> reorderCriteria(
    List<String> orderedIds,
  );

  /// Requires `performance.manage`. Throws [PerformanceReviewException] if
  /// review responses already reference this criterion — archive it instead.
  Future<void> deleteCriterion(String id);

  Future<List<PerformanceReview>> getMyReviews();

  /// Visible to the review's own employee, their reporting manager, or a
  /// `performance.manage` holder.
  Future<PerformanceReview> getReview(String id);

  /// Reviews where the caller is the reporting manager and action is due.
  Future<List<PerformanceReview>> getPendingManagerAction();

  /// Requires `performance.manage`.
  Future<List<PerformanceReview>> getPendingHrFinalization();

  /// Requires `performance.manage`. Every review company-wide still pending
  /// completion — not filtered to the caller's own direct reports.
  Future<List<PerformanceReview>> getAllPendingReviews();

  /// How the company-wide pending-review count has changed over the last
  /// [days] days (e.g. -1 once a review that was pending gets completed).
  /// Requires `performance.manage`.
  Future<int> getPendingReviewsDelta({int days = 7});

  /// Requires `performance.manage`. Every review that has completed the
  /// full workflow (rated and signed off by HR/Admin), company-wide.
  Future<List<PerformanceReview>> getFinalizedReviews();

  /// Requires `performance.manage`.
  Future<List<PerformanceReview>> getEmployeeReviews(String employeeId);

  /// Requires `performance.manage`. One summary per employee (their latest
  /// review, whatever its status) — for a directory-style list.
  Future<List<PerformanceReviewSummary>> getLatestReviewSummaries();

  /// Requires `performance.manage`. Dry run — returns what would be created
  /// without persisting anything.
  Future<List<Map<String, dynamic>>> previewDueCheck();

  /// Requires `performance.manage`.
  Future<int> runDueCheck();

  /// Requires `performance.manage`.
  Future<PerformanceReview> createManualReview({
    required String employeeId,
    required int reviewYear,
  });

  /// Allowed for the review employee's reporting manager, or anyone holding
  /// `performance.manage`.
  Future<PerformanceReview> completeReview(
    String id, {
    required List<PerformanceReviewResponseInput> responses,
  });

  /// Allowed only for the review's own employee.
  Future<PerformanceReview> setSelfAssessment(String id, String comments);

  /// Requires `performance.manage`.
  Future<PerformanceReview> finalizeReview(String id);

  /// Reverts a finalized review back to completed so it can be edited and
  /// finalized again. Requires `performance.manage`.
  Future<PerformanceReview> unfinalizeReview(String id);

  /// Requires `performance.manage`. Edits responses/comments regardless of
  /// status.
  Future<PerformanceReview> adminUpdateReview(
    String id, {
    String? employeeComments,
    List<PerformanceReviewResponseInput>? responses,
  });
}
