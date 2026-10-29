/// One criterion response value submitted when completing or editing a
/// review — a request payload, not the [PerformanceReviewResponse] read
/// model.
class PerformanceReviewResponseInput {
  const PerformanceReviewResponseInput({
    required this.responseId,
    this.ratingValue,
    this.textValue,
    this.commentValue,
  });

  final String responseId;
  final int? ratingValue;
  final String? textValue;
  final String? commentValue;

  Map<String, dynamic> toJson() => {
    'responseId': responseId,
    if (ratingValue != null) 'ratingValue': ratingValue,
    if (textValue != null) 'textValue': textValue,
    if (commentValue != null) 'commentValue': commentValue,
  };
}
