class ChecklistException implements Exception {
  const ChecklistException(this.message);

  final String message;

  @override
  String toString() => message;
}
