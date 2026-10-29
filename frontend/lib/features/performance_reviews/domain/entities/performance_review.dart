import 'performance_review_response.dart';
import 'performance_review_title.dart';

class PerformanceReview {
  const PerformanceReview({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    this.employeePhotoUrl,
    this.designation,
    this.department,
    this.reportingManagerName,
    required this.reviewYear,
    this.reviewPeriod = 2,
    required this.dueDate,
    required this.status,
    required this.responses,
    this.overallRating,
    this.employeeComments,
    this.completedByName,
    this.completedAt,
    this.completedAsManager,
    this.finalizedByName,
    this.finalizedAt,
    required this.createdAt,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final String? employeePhotoUrl;
  final String? designation;
  final String? department;
  final String? reportingManagerName;

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
  final List<PerformanceReviewResponse> responses;

  /// Key of [overallRatingLabels], set by the evaluator.
  final String? overallRating;

  /// Optional self-assessment the employee may add themselves.
  final String? employeeComments;
  final String? completedByName;
  final DateTime? completedAt;

  /// True if completed by the employee's actual reporting manager; false if
  /// an HR/Admin override was used instead.
  final bool? completedAsManager;
  final String? finalizedByName;
  final DateTime? finalizedAt;
  final DateTime createdAt;
}
