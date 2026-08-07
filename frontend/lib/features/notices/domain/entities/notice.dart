class Notice {
  const Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.authorName,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String authorName;
  final DateTime createdAt;
}
