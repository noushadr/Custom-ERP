/// One row of an article's version history — who changed it and when, not
/// the content itself.
class KnowledgeBaseArticleVersionSummary {
  const KnowledgeBaseArticleVersionSummary({
    required this.id,
    required this.versionNumber,
    required this.title,
    required this.editorName,
    required this.createdAt,
  });

  final String id;
  final int versionNumber;
  final String title;
  final String editorName;
  final DateTime createdAt;
}
