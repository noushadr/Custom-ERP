class NoticeException implements Exception {
  const NoticeException(this.message);

  final String message;

  @override
  String toString() => message;
}
