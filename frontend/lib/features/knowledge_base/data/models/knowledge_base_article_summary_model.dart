import '../../domain/entities/knowledge_base_file_info.dart';
import '../../domain/entities/knowledge_base_article_summary.dart';
import '../../domain/entities/knowledge_base_content_kind.dart';

class KnowledgeBaseArticleSummaryModel extends KnowledgeBaseArticleSummary {
  const KnowledgeBaseArticleSummaryModel({
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
  });

  factory KnowledgeBaseArticleSummaryModel.fromJson(
    Map<String, dynamic> json,
  ) => KnowledgeBaseArticleSummaryModel(
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
  );
}
