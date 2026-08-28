import 'package:zera_erp/features/knowledge_base/domain/entities/knowledge_base_article.dart';
import 'package:zera_erp/features/knowledge_base/domain/entities/knowledge_base_article_summary.dart';
import 'package:zera_erp/features/knowledge_base/domain/entities/knowledge_base_article_version.dart';
import 'package:zera_erp/features/knowledge_base/domain/entities/knowledge_base_article_version_summary.dart';
import 'package:zera_erp/features/knowledge_base/domain/entities/knowledge_base_visibility.dart';
import 'package:zera_erp/features/knowledge_base/domain/repositories/knowledge_base_repository.dart';

final _defaultContent = {
  'ops': [
    {'insert': 'Hello world\n'},
  ],
};

KnowledgeBaseArticleSummary buildTestKnowledgeBaseArticleSummary({
  String id = 'article-1',
  String title = 'Onboarding SOP',
  String visibilityType = KnowledgeBaseVisibility.everyone,
  String authorName = 'Jane Doe',
  String lastEditedByName = 'Jane Doe',
  int versionNumber = 1,
  bool isArchived = false,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return KnowledgeBaseArticleSummary(
    id: id,
    title: title,
    visibilityType: visibilityType,
    authorName: authorName,
    lastEditedByName: lastEditedByName,
    versionNumber: versionNumber,
    isArchived: isArchived,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    updatedAt: updatedAt ?? DateTime(2026, 1, 1),
  );
}

KnowledgeBaseArticle buildTestKnowledgeBaseArticle({
  String id = 'article-1',
  String title = 'Onboarding SOP',
  String visibilityType = KnowledgeBaseVisibility.everyone,
  String authorName = 'Jane Doe',
  String lastEditedByName = 'Jane Doe',
  int versionNumber = 1,
  bool isArchived = false,
  DateTime? createdAt,
  DateTime? updatedAt,
  dynamic content,
  List<String> targetRoleIds = const [],
  List<String> targetDepartmentIds = const [],
}) {
  return KnowledgeBaseArticle(
    id: id,
    title: title,
    visibilityType: visibilityType,
    authorName: authorName,
    lastEditedByName: lastEditedByName,
    versionNumber: versionNumber,
    isArchived: isArchived,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    updatedAt: updatedAt ?? DateTime(2026, 1, 1),
    content: content ?? _defaultContent,
    targetRoleIds: targetRoleIds,
    targetDepartmentIds: targetDepartmentIds,
  );
}

KnowledgeBaseArticleVersionSummary
buildTestKnowledgeBaseArticleVersionSummary({
  String id = 'version-1',
  int versionNumber = 1,
  String title = 'Onboarding SOP',
  String editorName = 'Jane Doe',
  DateTime? createdAt,
}) {
  return KnowledgeBaseArticleVersionSummary(
    id: id,
    versionNumber: versionNumber,
    title: title,
    editorName: editorName,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}

KnowledgeBaseArticleVersion buildTestKnowledgeBaseArticleVersion({
  String id = 'version-1',
  int versionNumber = 1,
  String title = 'Onboarding SOP',
  String editorName = 'Jane Doe',
  DateTime? createdAt,
  dynamic content,
}) {
  return KnowledgeBaseArticleVersion(
    id: id,
    versionNumber: versionNumber,
    title: title,
    editorName: editorName,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    content: content ?? _defaultContent,
  );
}

class FakeKnowledgeBaseRepository implements KnowledgeBaseRepository {
  FakeKnowledgeBaseRepository({
    this.articles = const [],
    this.articleById,
    this.versionHistory = const [],
    this.versionById,
    this.createArticleResult,
    this.updateArticleResult,
    this.createArticleError,
    this.updateArticleError,
    this.getArticleError,
  });

  final List<KnowledgeBaseArticleSummary> articles;
  final KnowledgeBaseArticle? articleById;
  final List<KnowledgeBaseArticleVersionSummary> versionHistory;
  final KnowledgeBaseArticleVersion? versionById;
  final KnowledgeBaseArticle? createArticleResult;
  final KnowledgeBaseArticle? updateArticleResult;
  final Object? createArticleError;
  final Object? updateArticleError;
  final Object? getArticleError;

  String? lastCreatedTitle;
  dynamic lastCreatedContent;
  String? lastCreatedVisibilityType;
  List<String>? lastCreatedTargetRoleIds;
  List<String>? lastCreatedTargetDepartmentIds;

  String? lastUpdatedId;
  String? lastUpdatedTitle;
  dynamic lastUpdatedContent;
  String? lastUpdatedVisibilityType;
  List<String>? lastUpdatedTargetRoleIds;
  List<String>? lastUpdatedTargetDepartmentIds;
  bool? lastUpdatedIsArchived;

  @override
  Future<List<KnowledgeBaseArticleSummary>> getArticles({
    bool includeArchived = false,
  }) async => articles;

  @override
  Future<KnowledgeBaseArticle> getArticle(String id) async {
    if (getArticleError != null) throw getArticleError!;
    return articleById ?? buildTestKnowledgeBaseArticle(id: id);
  }

  @override
  Future<List<KnowledgeBaseArticleVersionSummary>> getVersionHistory(
    String articleId,
  ) async => versionHistory;

  @override
  Future<KnowledgeBaseArticleVersion> getVersion(
    String articleId,
    String versionId,
  ) async => versionById ?? buildTestKnowledgeBaseArticleVersion(id: versionId);

  @override
  Future<KnowledgeBaseArticle> createArticle({
    required String title,
    required dynamic content,
    required String visibilityType,
    List<String>? targetRoleIds,
    List<String>? targetDepartmentIds,
  }) async {
    lastCreatedTitle = title;
    lastCreatedContent = content;
    lastCreatedVisibilityType = visibilityType;
    lastCreatedTargetRoleIds = targetRoleIds;
    lastCreatedTargetDepartmentIds = targetDepartmentIds;
    if (createArticleError != null) throw createArticleError!;
    return createArticleResult ?? buildTestKnowledgeBaseArticle(title: title);
  }

  @override
  Future<KnowledgeBaseArticle> updateArticle(
    String id, {
    String? title,
    dynamic content,
    String? visibilityType,
    List<String>? targetRoleIds,
    List<String>? targetDepartmentIds,
    bool? isArchived,
  }) async {
    lastUpdatedId = id;
    lastUpdatedTitle = title;
    lastUpdatedContent = content;
    lastUpdatedVisibilityType = visibilityType;
    lastUpdatedTargetRoleIds = targetRoleIds;
    lastUpdatedTargetDepartmentIds = targetDepartmentIds;
    lastUpdatedIsArchived = isArchived;
    if (updateArticleError != null) throw updateArticleError!;
    return updateArticleResult ?? buildTestKnowledgeBaseArticle(id: id);
  }
}
