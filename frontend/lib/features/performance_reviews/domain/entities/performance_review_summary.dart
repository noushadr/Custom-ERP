import 'performance_review_title.dart';

/// A lightweight per-employee summary of their latest performance review —
/// just enough to answer "when was their last review done, or is it still
/// pending" for a list view like the employee directory, without the full
/// criterion snapshot [PerformanceReview] carries.
class PerformanceReviewSummary {
  const PerformanceReviewSummary({
    required this.employeeId,
    required this.reviewYear,
    this.reviewPeriod = 2,
    required this.dueDate,
    required this.status,
    this.completedAt,
    this.finalizedAt,
  });

  final String employeeId;

  /// Calendar year of the review cycle.
  final int reviewYear;

  /// 1 = June cycle, 2 = December cycle.
  final int reviewPeriod;

  /// e.g. "June 2026 Review".
  String get title => performanceReviewTitle(reviewYear, reviewPeriod);

  /// ISO 'YYYY-MM-DD' — pass to formatDisplayDate/formatMonthDay.
  final String dueDate;

  /// 'pending', 'completed', or 'finalized'.
  final String status;
  final DateTime? completedAt;
  final DateTime? finalizedAt;
}
