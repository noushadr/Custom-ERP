/// A list-row shape — title, author, and dates only, no content or
/// targeting detail. Used for the list page's Recently Published/Recently
/// Updated/All Articles sections.
class KnowledgeBaseArticleSummary {
  const KnowledgeBaseArticleSummary({
    required this.id,
    required this.title,
    required this.visibilityType,
    required this.authorName,
    required this.lastEditedByName,
    required this.versionNumber,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;

  /// One of KnowledgeBaseVisibility's values.
  final String visibilityType;
  final String authorName;
  final String lastEditedByName;
  final int versionNumber;
  final bool isArchived;

  /// Doubles as "publication date".
  final DateTime createdAt;

  /// Doubles as "last updated date".
  final DateTime updatedAt;
}
