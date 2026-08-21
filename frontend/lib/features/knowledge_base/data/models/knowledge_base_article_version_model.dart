import '../../domain/entities/knowledge_base_article_version.dart';

class KnowledgeBaseArticleVersionModel extends KnowledgeBaseArticleVersion {
  const KnowledgeBaseArticleVersionModel({
    required super.id,
    required super.versionNumber,
    required super.title,
    required super.editorName,
    required super.createdAt,
    required super.content,
  });

  factory KnowledgeBaseArticleVersionModel.fromJson(
    Map<String, dynamic> json,
  ) => KnowledgeBaseArticleVersionModel(
    id: json['id'] as String,
    versionNumber: json['versionNumber'] as int,
    title: json['title'] as String,
    editorName: json['editorName'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    content: json['content'],
  );
}
