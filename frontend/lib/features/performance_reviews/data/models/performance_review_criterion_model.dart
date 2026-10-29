import '../../domain/entities/performance_review_criterion.dart';

class PerformanceReviewCriterionModel extends PerformanceReviewCriterion {
  const PerformanceReviewCriterionModel({
    required super.id,
    required super.name,
    required super.responseType,
    required super.sortOrder,
    required super.isArchived,
    super.section,
    super.hasComment,
  });

  factory PerformanceReviewCriterionModel.fromJson(Map<String, dynamic> json) =>
      PerformanceReviewCriterionModel(
        id: json['id'] as String,
        name: json['name'] as String,
        responseType: json['responseType'] as String,
        sortOrder: json['sortOrder'] as int,
        isArchived: json['isArchived'] as bool,
        section: json['section'] as String?,
        hasComment: json['hasComment'] as bool? ?? false,
      );
}
