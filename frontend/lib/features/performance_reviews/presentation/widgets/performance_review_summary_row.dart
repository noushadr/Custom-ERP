import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../domain/entities/performance_review.dart';
import '../pages/performance_review_detail_page.dart';
import 'performance_review_status_badge.dart';

/// One row summarizing a review — used both on an employee's profile (where
/// the employee is implicit) and in lists spanning multiple employees (where
/// [showEmployeeName] adds their name to the title, mirroring how
/// RequestsPage's rows show "{subject} — {requesterName}").
class PerformanceReviewSummaryRow extends StatelessWidget {
  const PerformanceReviewSummaryRow({
    super.key,
    required this.review,
    this.showEmployeeName = false,
  });

  final PerformanceReview review;
  final bool showEmployeeName;

  @override
  Widget build(BuildContext context) {
    final title = showEmployeeName
        ? 'Year ${review.reviewYear} Review — ${review.employeeName}'
        : 'Year ${review.reviewYear} Review';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PerformanceReviewDetailPage(reviewId: review.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Due ${formatDisplayDate(review.dueDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            PerformanceReviewStatusBadge(status: review.status),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
