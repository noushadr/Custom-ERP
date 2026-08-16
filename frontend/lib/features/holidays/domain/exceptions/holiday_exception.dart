class HolidayException implements Exception {
  const HolidayException(this.message);

  final String message;

  @override
  String toString() => message;
}
