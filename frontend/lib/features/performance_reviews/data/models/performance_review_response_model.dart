import '../../domain/entities/performance_review_response.dart';

class PerformanceReviewResponseModel extends PerformanceReviewResponse {
  const PerformanceReviewResponseModel({
    required super.id,
    super.criterionId,
    required super.criterionName,
    required super.responseType,
    required super.sortOrder,
    super.ratingValue,
    super.textValue,
  });

  factory PerformanceReviewResponseModel.fromJson(Map<String, dynamic> json) =>
      PerformanceReviewResponseModel(
        id: json['id'] as String,
        criterionId: json['criterionId'] as String?,
        criterionName: json['criterionName'] as String,
        responseType: json['responseType'] as String,
        sortOrder: json['sortOrder'] as int,
        ratingValue: json['ratingValue'] as int?,
        textValue: json['textValue'] as String?,
      );
}
