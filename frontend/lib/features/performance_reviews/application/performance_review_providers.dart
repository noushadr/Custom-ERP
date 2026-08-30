import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/performance_review_remote_data_source.dart';
import '../data/repositories/performance_review_repository_impl.dart';
import '../domain/entities/performance_review.dart';
import '../domain/entities/performance_review_criterion.dart';
import '../domain/entities/performance_review_summary.dart';
import '../domain/repositories/performance_review_repository.dart';

final performanceReviewRemoteDataSourceProvider =
    Provider<PerformanceReviewRemoteDataSource>(
      (ref) => PerformanceReviewRemoteDataSource(
        ref.watch(dioClientProvider).dio,
      ),
    );

final performanceReviewRepositoryProvider = Provider<PerformanceReviewRepository>(
  (ref) => PerformanceReviewRepositoryImpl(
    ref.watch(performanceReviewRemoteDataSourceProvider),
  ),
);

// Every provider below re-watches authControllerProvider purely to create a
// dependency edge, so switching identity (impersonate/returnToAdmin/logout)
// triggers a refetch — see the longer explanation in employee_providers.dart.

final performanceReviewCriteriaProvider = FutureProvider.autoDispose
    .family<List<PerformanceReviewCriterion>, bool>((ref, includeArchived) {
      ref.watch(authControllerProvider);
      return ref
          .watch(performanceReviewRepositoryProvider)
          .getCriteria(includeArchived: includeArchived);
    });

final myPerformanceReviewsProvider =
    FutureProvider.autoDispose<List<PerformanceReview>>((ref) {
      ref.watch(authControllerProvider);
      return ref.watch(performanceReviewRepositoryProvider).getMyReviews();
    });

final performanceReviewProvider = FutureProvider.autoDispose
    .family<PerformanceReview, String>((ref, id) {
      ref.watch(authControllerProvider);
      return ref.watch(performanceReviewRepositoryProvider).getReview(id);
    });

final pendingManagerActionReviewsProvider =
    FutureProvider.autoDispose<List<PerformanceReview>>((ref) {
      ref.watch(authControllerProvider);
      return ref
          .watch(performanceReviewRepositoryProvider)
          .getPendingManagerAction();
    });

final pendingHrFinalizationReviewsProvider =
    FutureProvider.autoDispose<List<PerformanceReview>>((ref) {
      ref.watch(authControllerProvider);
      return ref
          .watch(performanceReviewRepositoryProvider)
          .getPendingHrFinalization();
    });

/// Every review company-wide still pending completion — for a
/// `performance.manage` holder's dashboard overview, not filtered to the
/// caller's own direct reports the way [pendingManagerActionReviewsProvider]
/// is.
final allPendingPerformanceReviewsProvider =
    FutureProvider.autoDispose<List<PerformanceReview>>((ref) {
      ref.watch(authControllerProvider);
      return ref
          .watch(performanceReviewRepositoryProvider)
          .getAllPendingReviews();
    });

/// How the company-wide pending-review count has changed over the last 7
/// days — see `PerformanceReviewsService.getPendingReviewsDelta` for how
/// "7 days ago" is reconstructed from `createdAt`/`completedAt` rather than
/// a new snapshot.
final pendingReviewsDeltaProvider = FutureProvider.autoDispose<int>((ref) {
  ref.watch(authControllerProvider);
  return ref
      .watch(performanceReviewRepositoryProvider)
      .getPendingReviewsDelta();
});

/// Every review that has completed the full workflow — company-wide.
final finalizedPerformanceReviewsProvider =
    FutureProvider.autoDispose<List<PerformanceReview>>((ref) {
      ref.watch(authControllerProvider);
      return ref
          .watch(performanceReviewRepositoryProvider)
          .getFinalizedReviews();
    });

final employeePerformanceReviewsProvider = FutureProvider.autoDispose
    .family<List<PerformanceReview>, String>((ref, employeeId) {
      ref.watch(authControllerProvider);
      return ref
          .watch(performanceReviewRepositoryProvider)
          .getEmployeeReviews(employeeId);
    });

/// Keyed by employeeId for O(1) lookup in list views (e.g. the employee
/// directory) — a `performance.manage` holder fetches every employee's
/// latest review in one call rather than one request per card.
final latestPerformanceReviewsByEmployeeProvider = FutureProvider.autoDispose<
    Map<String, PerformanceReviewSummary>>((ref) async {
  ref.watch(authControllerProvider);
  final summaries = await ref
      .watch(performanceReviewRepositoryProvider)
      .getLatestReviewSummaries();
  return {for (final summary in summaries) summary.employeeId: summary};
});
