/// The evaluator-supplied, review-level field submitted alongside the
/// per-criterion responses — a request payload, like
/// [PerformanceReviewResponseInput].
class PerformanceReviewFormFields {
  const PerformanceReviewFormFields({this.overallRating});

  /// One of [overallRatingLabels]' keys.
  final String? overallRating;

  Map<String, dynamic> toJson() => {
    if (overallRating != null) 'overallRating': overallRating,
  };
}

/// The "Overall Performance Rating" choices, in display order.
const overallRatingLabels = <String, String>{
  'needs_improvement': 'Needs Improvement',
  'meets_expectations': 'Meets Expectations',
  'exceeds_expectations': 'Exceeds Expectations',
  'outstanding': 'Outstanding',
};
