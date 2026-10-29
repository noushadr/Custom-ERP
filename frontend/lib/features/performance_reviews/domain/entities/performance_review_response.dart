class PerformanceReviewResponse {
  const PerformanceReviewResponse({
    required this.id,
    this.criterionId,
    required this.criterionName,
    required this.responseType,
    required this.sortOrder,
    this.section,
    this.hasComment = false,
    this.ratingValue,
    this.textValue,
    this.commentValue,
  });

  final String id;
  final String? criterionId;
  final String criterionName;

  /// 'rating' or 'text'.
  final String responseType;
  final int sortOrder;

  /// Heading this criterion is grouped under on the form, if any.
  final String? section;

  /// Whether a free-text comment is collected beside the rating.
  final bool hasComment;

  /// 1-5, set only when [responseType] is 'rating'.
  final int? ratingValue;

  /// Set only when [responseType] is 'text'.
  final String? textValue;

  /// The comment beside a rating, when [hasComment].
  final String? commentValue;
}
