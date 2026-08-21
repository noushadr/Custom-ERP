import '../../domain/entities/performance_review.dart';
import 'performance_review_response_model.dart';

class PerformanceReviewModel extends PerformanceReview {
  const PerformanceReviewModel({
    required super.id,
    required super.employeeId,
    required super.employeeName,
    super.employeePhotoUrl,
    required super.reviewYear,
    required super.dueDate,
    required super.status,
    required super.responses,
    super.employeeComments,
    super.completedByName,
    super.completedAt,
    super.completedAsManager,
    super.finalizedByName,
    super.finalizedAt,
    required super.createdAt,
  });

  factory PerformanceReviewModel.fromJson(Map<String, dynamic> json) =>
      PerformanceReviewModel(
        id: json['id'] as String,
        employeeId: json['employeeId'] as String,
        employeeName: json['employeeName'] as String,
        employeePhotoUrl: json['employeePhotoUrl'] as String?,
        reviewYear: json['reviewYear'] as int,
        dueDate: json['dueDate'] as String,
        status: json['status'] as String,
        responses: (json['responses'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(PerformanceReviewResponseModel.fromJson)
            .toList(),
        employeeComments: json['employeeComments'] as String?,
        completedByName: json['completedByName'] as String?,
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.parse(json['completedAt'] as String),
        completedAsManager: json['completedAsManager'] as bool?,
        finalizedByName: json['finalizedByName'] as String?,
        finalizedAt: json['finalizedAt'] == null
            ? null
            : DateTime.parse(json['finalizedAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
