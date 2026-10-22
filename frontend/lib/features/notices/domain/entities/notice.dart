class Notice {
  const Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.authorName,
    required this.createdAt,
    this.expiresAt,
  });

  final String id;
  final String title;
  final String body;
  final String authorName;
  final DateTime createdAt;

  /// When the notice stops showing to staff; null means it never expires.
  final DateTime? expiresAt;

  /// True once the end date has passed. Staff never receive expired notices;
  /// only someone who manages notices does, so they can edit, extend or
  /// delete them.
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
}
