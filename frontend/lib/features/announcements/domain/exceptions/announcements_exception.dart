class AnnouncementsException implements Exception {
  const AnnouncementsException(this.message);

  final String message;

  @override
  String toString() => message;
}
