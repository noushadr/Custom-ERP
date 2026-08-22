import '../../domain/entities/performance_review_summary.dart';

class PerformanceReviewSummaryModel extends PerformanceReviewSummary {
  const PerformanceReviewSummaryModel({
    required super.employeeId,
    required super.reviewYear,
    required super.dueDate,
    required super.status,
    super.completedAt,
    super.finalizedAt,
  });

  factory PerformanceReviewSummaryModel.fromJson(Map<String, dynamic> json) =>
      PerformanceReviewSummaryModel(
        employeeId: json['employeeId'] as String,
        reviewYear: json['reviewYear'] as int,
        dueDate: json['dueDate'] as String,
        status: json['status'] as String,
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.parse(json['completedAt'] as String),
        finalizedAt: json['finalizedAt'] == null
            ? null
            : DateTime.parse(json['finalizedAt'] as String),
      );
}
