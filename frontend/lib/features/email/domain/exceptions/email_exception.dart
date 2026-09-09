class EmailException implements Exception {
  const EmailException(this.message);

  final String message;

  @override
  String toString() => message;
}
