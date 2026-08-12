class LeaveException implements Exception {
  const LeaveException(this.message);

  final String message;

  @override
  String toString() => message;
}
