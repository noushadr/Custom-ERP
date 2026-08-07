class RequestException implements Exception {
  const RequestException(this.message);

  final String message;

  @override
  String toString() => message;
}
