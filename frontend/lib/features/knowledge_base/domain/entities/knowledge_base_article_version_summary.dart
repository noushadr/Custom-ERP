import 'knowledge_base_file_info.dart';

/// One row of an article's version history — who changed it and when, not
/// the content itself.
class KnowledgeBaseArticleVersionSummary {
  const KnowledgeBaseArticleVersionSummary({
    required this.id,
    required this.versionNumber,
    required this.title,
    required this.editorName,
    required this.createdAt,
    this.files = const [],
  });

  final String id;
  final int versionNumber;
  final String title;
  final String editorName;
  final DateTime createdAt;

  /// The files this version pointed at — empty for a version of a written
  /// article.
  final List<KnowledgeBaseFileInfo> files;

  bool get hasFile => files.isNotEmpty;
}
