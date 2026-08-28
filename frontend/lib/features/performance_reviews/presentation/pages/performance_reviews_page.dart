import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../application/performance_review_providers.dart';
import '../widgets/performance_review_summary_row.dart';

/// Consolidates everything about performance reviews in one place: the
/// viewer's own review history, any reviews awaiting their action as a
/// reporting manager, and — for HR/Admin — company-wide visibility into
/// reviews awaiting finalization, still pending, and already finalized.
/// Mirrors RequestsPage's section-based structure.
class PerformanceReviewsPage extends ConsumerWidget {
  const PerformanceReviewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final authUser = authState is AuthAuthenticated ? authState.user : null;
    final canFinalize = authUser?.hasPermission('performance.manage') ?? false;
    // Plausible-manager roles only, same reasoning as RequestsPage's
    // canSeeManagerApprovals — an empty section for everyone else would just
    // be noise, since pendingManagerActionReviewsProvider naturally returns
    // nothing for someone with no direct reports anyway.
    final canSeeManagerAction =
        authUser?.role == 'Super Admin' ||
        authUser?.role == 'HR/Manager' ||
        authUser?.role == 'Team Lead';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _MyReviewsSection(),
                const SizedBox(height: 16),
                if (canSeeManagerAction) ...[
                  const _PendingManagerActionSection(),
                  const SizedBox(height: 16),
                ],
                if (canFinalize) ...[
                  const _PendingHrFinalizationSection(),
                  const SizedBox(height: 16),
                  const _PendingReviewsSection(),
                  const SizedBox(height: 16),
                  const _FinalizedReviewsSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyReviewsSection extends ConsumerWidget {
  const _MyReviewsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(myPerformanceReviewsProvider);

    return FormSection(
      title: 'My Reviews',
      child: reviewsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load your reviews.'),
        data: (reviews) {
          if (reviews.isEmpty) {
            return Text(
              "You don't have any performance reviews yet.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            );
          }
          final sorted = [...reviews]
            ..sort((a, b) => b.reviewYear.compareTo(a.reviewYear));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < sorted.length; i++) ...[
                PerformanceReviewSummaryRow(review: sorted[i]),
                if (i < sorted.length - 1)
                  const Divider(height: 20, color: AppColors.borderSubtle),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Reviews for one of this viewer's direct reports, pending their action as
/// reporting manager. Empty for anyone without direct reports.
class _PendingManagerActionSection extends ConsumerWidget {
  const _PendingManagerActionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(pendingManagerActionReviewsProvider);

    return FormSection(
      title: 'Reviews Awaiting My Action',
      child: reviewsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load pending reviews.'),
        data: (reviews) {
          if (reviews.isEmpty) {
            return Text(
              'Nothing is waiting for your review right now.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < reviews.length; i++) ...[
                PerformanceReviewSummaryRow(
                  review: reviews[i],
                  showEmployeeName: true,
                ),
                if (i < reviews.length - 1)
                  const Divider(height: 20, color: AppColors.borderSubtle),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Reviews the manager has completed and are awaiting HR/Admin finalization.
class _PendingHrFinalizationSection extends ConsumerWidget {
  const _PendingHrFinalizationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(pendingHrFinalizationReviewsProvider);

    return FormSection(
      title: 'Reviews Awaiting Finalization',
      child: reviewsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load pending reviews.'),
        data: (reviews) {
          if (reviews.isEmpty) {
            return Text(
              'Nothing is awaiting finalization right now.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < reviews.length; i++) ...[
                PerformanceReviewSummaryRow(
                  review: reviews[i],
                  showEmployeeName: true,
                ),
                if (i < reviews.length - 1)
                  const Divider(height: 20, color: AppColors.borderSubtle),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Every review, company-wide, still awaiting the reporting manager's (or
/// HR's) completion — not filtered to the caller's own direct reports the
/// way [_PendingManagerActionSection] is. Gives HR/Admin the same
/// full-company visibility here as [_FinalizedReviewsSection] does.
class _PendingReviewsSection extends ConsumerWidget {
  const _PendingReviewsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(allPendingPerformanceReviewsProvider);

    return FormSection(
      title: 'Pending Reviews',
      child: reviewsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load pending reviews.'),
        data: (reviews) {
          if (reviews.isEmpty) {
            return Text(
              'No reviews are pending right now.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < reviews.length; i++) ...[
                PerformanceReviewSummaryRow(
                  review: reviews[i],
                  showEmployeeName: true,
                ),
                if (i < reviews.length - 1)
                  const Divider(height: 20, color: AppColors.borderSubtle),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Every review, company-wide, that has completed the full workflow — rated
/// and signed off by HR/Admin. A review-history view, so most-recently-
/// finalized first (unlike the action-queue sections above, which don't
/// need a particular order).
class _FinalizedReviewsSection extends ConsumerWidget {
  const _FinalizedReviewsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(finalizedPerformanceReviewsProvider);

    return FormSection(
      title: 'Finalized Reviews',
      child: reviewsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load finalized reviews.'),
        data: (reviews) {
          if (reviews.isEmpty) {
            return Text(
              'No reviews have been finalized yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            );
          }
          final sorted = [...reviews]..sort((a, b) {
            final aAt = a.finalizedAt ?? a.createdAt;
            final bAt = b.finalizedAt ?? b.createdAt;
            return bAt.compareTo(aAt);
          });
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < sorted.length; i++) ...[
                PerformanceReviewSummaryRow(
                  review: sorted[i],
                  showEmployeeName: true,
                ),
                if (i < sorted.length - 1)
                  const Divider(height: 20, color: AppColors.borderSubtle),
              ],
            ],
          );
        },
      ),
    );
  }
}
