import '../../../../shared/utils/photo_url.dart';
import '../../domain/entities/performance_review.dart';
import 'performance_review_response_model.dart';

class PerformanceReviewModel extends PerformanceReview {
  const PerformanceReviewModel({
    required super.id,
    required super.employeeId,
    required super.employeeName,
    super.employeePhotoUrl,
    super.designation,
    super.department,
    super.reportingManagerName,
    required super.reviewYear,
    super.reviewPeriod,
    required super.dueDate,
    required super.status,
    required super.responses,
    super.overallRating,
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
        employeePhotoUrl: resolvePhotoUrl(json['employeePhotoUrl'] as String?),
        designation: json['designation'] as String?,
        department: json['department'] as String?,
        reportingManagerName: json['reportingManagerName'] as String?,
        reviewYear: json['reviewYear'] as int,
        reviewPeriod: json['reviewPeriod'] as int? ?? 2,
        dueDate: json['dueDate'] as String,
        status: json['status'] as String,
        responses: (json['responses'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(PerformanceReviewResponseModel.fromJson)
            .toList(),
        overallRating: json['overallRating'] as String?,
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
