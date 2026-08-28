class PerformanceReviewCriterion {
  const PerformanceReviewCriterion({
    required this.id,
    required this.name,
    required this.responseType,
    required this.sortOrder,
    required this.isArchived,
  });

  final String id;
  final String name;

  /// 'rating' or 'text'.
  final String responseType;
  final int sortOrder;
  final bool isArchived;
}
