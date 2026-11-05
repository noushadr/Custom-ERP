import '../../domain/entities/knowledge_base_file_info.dart';
import '../../domain/entities/knowledge_base_article.dart';
import '../../domain/entities/knowledge_base_content_kind.dart';

class KnowledgeBaseArticleModel extends KnowledgeBaseArticle {
  const KnowledgeBaseArticleModel({
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
    super.files,
    super.targetRoleNames,
    super.targetDepartmentNames,
    required super.content,
    required super.targetRoleIds,
    required super.targetDepartmentIds,
  });

  factory KnowledgeBaseArticleModel.fromJson(
    Map<String, dynamic> json,
  ) => KnowledgeBaseArticleModel(
    id: json['id'] as String,
    title: json['title'] as String,
    visibilityType: json['visibilityType'] as String,
    authorName: json['authorName'] as String,
    lastEditedByName: json['lastEditedByName'] as String,
    versionNumber: json['versionNumber'] as int,
    isArchived: json['isArchived'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    contentKind:
        json['contentKind'] as String? ?? KnowledgeBaseContentKind.richText,
    files: knowledgeBaseFilesFromJson(json['files']),
    targetRoleNames: (json['targetRoleNames'] as List<dynamic>? ?? [])
        .cast<String>(),
    targetDepartmentNames:
        (json['targetDepartmentNames'] as List<dynamic>? ?? []).cast<String>(),
    content: json['content'],
    targetRoleIds: (json['targetRoleIds'] as List<dynamic>? ?? [])
        .cast<String>(),
    targetDepartmentIds: (json['targetDepartmentIds'] as List<dynamic>? ?? [])
        .cast<String>(),
  );
}
