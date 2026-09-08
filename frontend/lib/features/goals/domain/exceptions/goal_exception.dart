class GoalException implements Exception {
  const GoalException(this.message);

  final String message;

  @override
  String toString() => message;
}
