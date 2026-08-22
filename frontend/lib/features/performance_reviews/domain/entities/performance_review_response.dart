class PerformanceReviewResponse {
  const PerformanceReviewResponse({
    required this.id,
    this.criterionId,
    required this.criterionName,
    required this.responseType,
    required this.sortOrder,
    this.ratingValue,
    this.textValue,
  });

  final String id;
  final String? criterionId;
  final String criterionName;

  /// 'rating' or 'text'.
  final String responseType;
  final int sortOrder;

  /// 1-5, set only when [responseType] is 'rating'.
  final int? ratingValue;

  /// Set only when [responseType] is 'text'.
  final String? textValue;
}
