import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../application/performance_review_providers.dart';
import 'performance_review_summary_row.dart';

/// Year-by-year performance review history for an employee, shown on their
/// profile — visible to the employee themselves and to anyone holding
/// `performance.manage` (a separate permission from `employees.manage`, so
/// this checks it independently rather than trusting a passed-down
/// `canManage` meant for other sections).
class EmployeePerformanceReviewsSection extends ConsumerWidget {
  const EmployeePerformanceReviewsSection({
    super.key,
    required this.employeeId,
    required this.isSelf,
  });

  final String employeeId;
  final bool isSelf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final hasOverride =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('performance.manage');

    if (!isSelf && !hasOverride) return const SizedBox.shrink();

    final reviewsAsync = isSelf
        ? ref.watch(myPerformanceReviewsProvider)
        : ref.watch(employeePerformanceReviewsProvider(employeeId));

    return FormSection(
      title: 'Performance Reviews',
      child: reviewsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load performance reviews.'),
        data: (reviews) {
          if (reviews.isEmpty) {
            return Text(
              'No performance reviews yet.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
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
                  const Divider(height: 16, color: AppColors.borderSubtle),
              ],
            ],
          );
        },
      ),
    );
  }
}
