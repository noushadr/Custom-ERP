class PerformanceReviewCriterion {
  const PerformanceReviewCriterion({
    required this.id,
    required this.name,
    required this.responseType,
    required this.sortOrder,
    required this.isArchived,
    this.section,
    this.hasComment = false,
  });

  final String id;
  final String name;

  /// 'rating' or 'text'.
  final String responseType;
  final int sortOrder;
  final bool isArchived;

  /// Heading this criterion is grouped under on the form, if any.
  final String? section;

  /// Rating criteria only: also collect a comment beside the rating.
  final bool hasComment;
}
