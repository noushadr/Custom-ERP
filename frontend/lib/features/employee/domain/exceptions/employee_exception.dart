class EmployeeException implements Exception {
  const EmployeeException(this.message);

  final String message;

  @override
  String toString() => message;
}
