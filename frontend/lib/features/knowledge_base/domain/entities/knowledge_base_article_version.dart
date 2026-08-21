import 'knowledge_base_article_version_summary.dart';

/// A single past version's full content — a read-only historical snapshot.
class KnowledgeBaseArticleVersion extends KnowledgeBaseArticleVersionSummary {
  const KnowledgeBaseArticleVersion({
    required super.id,
    required super.versionNumber,
    required super.title,
    required super.editorName,
    required super.createdAt,
    required this.content,
  });

  final dynamic content;
}
