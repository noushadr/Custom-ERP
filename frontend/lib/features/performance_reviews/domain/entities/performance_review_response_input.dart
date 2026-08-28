/// One criterion response value submitted when completing or editing a
/// review — a request payload, not the [PerformanceReviewResponse] read
/// model.
class PerformanceReviewResponseInput {
  const PerformanceReviewResponseInput({
    required this.responseId,
    this.ratingValue,
    this.textValue,
  });

  final String responseId;
  final int? ratingValue;
  final String? textValue;

  Map<String, dynamic> toJson() => {
    'responseId': responseId,
    if (ratingValue != null) 'ratingValue': ratingValue,
    if (textValue != null) 'textValue': textValue,
  };
}
