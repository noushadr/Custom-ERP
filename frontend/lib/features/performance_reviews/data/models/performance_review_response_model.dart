import '../../domain/entities/performance_review_response.dart';

class PerformanceReviewResponseModel extends PerformanceReviewResponse {
  const PerformanceReviewResponseModel({
    required super.id,
    super.criterionId,
    required super.criterionName,
    required super.responseType,
    required super.sortOrder,
    super.section,
    super.hasComment,
    super.ratingValue,
    super.textValue,
    super.commentValue,
  });

  factory PerformanceReviewResponseModel.fromJson(Map<String, dynamic> json) =>
      PerformanceReviewResponseModel(
        id: json['id'] as String,
        criterionId: json['criterionId'] as String?,
        criterionName: json['criterionName'] as String,
        responseType: json['responseType'] as String,
        sortOrder: json['sortOrder'] as int,
        section: json['section'] as String?,
        hasComment: json['hasComment'] as bool? ?? false,
        ratingValue: json['ratingValue'] as int?,
        textValue: json['textValue'] as String?,
        commentValue: json['commentValue'] as String?,
      );
}
