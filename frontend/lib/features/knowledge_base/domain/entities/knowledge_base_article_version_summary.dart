/// One row of an article's version history — who changed it and when, not
/// the content itself.
class KnowledgeBaseArticleVersionSummary {
  const KnowledgeBaseArticleVersionSummary({
    required this.id,
    required this.versionNumber,
    required this.title,
    required this.editorName,
    required this.createdAt,
    this.fileName,
    this.fileMimeType,
    this.fileSizeBytes,
  });

  final String id;
  final int versionNumber;
  final String title;
  final String editorName;
  final DateTime createdAt;

  /// The file this version pointed at — null for a version of a written
  /// article.
  final String? fileName;
  final String? fileMimeType;
  final int? fileSizeBytes;

  bool get hasFile => fileName != null;
}
