/// A lightweight per-employee summary of their latest performance review —
/// just enough to answer "when was their last review done, or is it still
/// pending" for a list view like the employee directory, without the full
/// criterion snapshot [PerformanceReview] carries.
class PerformanceReviewSummary {
  const PerformanceReviewSummary({
    required this.employeeId,
    required this.reviewYear,
    required this.dueDate,
    required this.status,
    this.completedAt,
    this.finalizedAt,
  });

  final String employeeId;

  /// Years of service this review covers, e.g. 1 for "Year 1 Review".
  final int reviewYear;

  /// ISO 'YYYY-MM-DD' — pass to formatDisplayDate/formatMonthDay.
  final String dueDate;

  /// 'pending', 'completed', or 'finalized'.
  final String status;
  final DateTime? completedAt;
  final DateTime? finalizedAt;
}
