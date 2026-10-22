import 'knowledge_base_article_summary.dart';

/// The full article, including its current rich-text content and targeting
/// — used by the article-view and editor pages. For an uploaded-file article
/// [content] is just an empty document and the file details on the summary
/// describe the upload.
class KnowledgeBaseArticle extends KnowledgeBaseArticleSummary {
  const KnowledgeBaseArticle({
    required super.id,
    required super.title,
    required super.visibilityType,
    required super.authorName,
    required super.lastEditedByName,
    required super.versionNumber,
    required super.isArchived,
    required super.createdAt,
    required super.updatedAt,
    super.contentKind,
    super.fileName,
    super.fileMimeType,
    super.fileSizeBytes,
    required this.content,
    required this.targetRoleIds,
    required this.targetDepartmentIds,
  });

  /// The current content as a Quill Delta — passed straight to the
  /// editor/viewer without interpretation here.
  final dynamic content;
  final List<String> targetRoleIds;
  final List<String> targetDepartmentIds;
}
