import 'performance_review_response.dart';

class PerformanceReview {
  const PerformanceReview({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    this.employeePhotoUrl,
    required this.reviewYear,
    required this.dueDate,
    required this.status,
    required this.responses,
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

  /// Years of service this review covers, e.g. 1 for "Year 1 Review".
  final int reviewYear;

  /// ISO 'YYYY-MM-DD' — pass to formatDisplayDate/formatMonthDay.
  final String dueDate;

  /// 'pending', 'completed', or 'finalized'.
  final String status;
  final List<PerformanceReviewResponse> responses;

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
