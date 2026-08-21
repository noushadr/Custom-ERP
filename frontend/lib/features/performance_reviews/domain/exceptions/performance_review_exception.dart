class PerformanceReviewException implements Exception {
  const PerformanceReviewException(this.message);

  final String message;

  @override
  String toString() => message;
}
