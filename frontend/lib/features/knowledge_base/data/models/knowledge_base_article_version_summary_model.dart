import '../../domain/entities/knowledge_base_article_version_summary.dart';

class KnowledgeBaseArticleVersionSummaryModel
    extends KnowledgeBaseArticleVersionSummary {
  const KnowledgeBaseArticleVersionSummaryModel({
    required super.id,
    required super.versionNumber,
    required super.title,
    required super.editorName,
    required super.createdAt,
    super.fileName,
    super.fileMimeType,
    super.fileSizeBytes,
  });

  factory KnowledgeBaseArticleVersionSummaryModel.fromJson(
    Map<String, dynamic> json,
  ) => KnowledgeBaseArticleVersionSummaryModel(
    id: json['id'] as String,
    versionNumber: json['versionNumber'] as int,
    title: json['title'] as String,
    editorName: json['editorName'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    fileName: json['fileName'] as String?,
    fileMimeType: json['fileMimeType'] as String?,
    fileSizeBytes: json['fileSizeBytes'] as int?,
  );
}
