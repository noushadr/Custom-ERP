import 'dart:typed_data';
import 'package:zera_erp/features/knowledge_base/domain/entities/knowledge_base_article.dart';
import 'package:zera_erp/features/knowledge_base/domain/entities/knowledge_base_article_summary.dart';
import 'package:zera_erp/features/knowledge_base/domain/entities/knowledge_base_article_version.dart';
import 'package:zera_erp/features/knowledge_base/domain/entities/knowledge_base_article_version_summary.dart';
import 'package:zera_erp/features/knowledge_base/domain/entities/knowledge_base_content_kind.dart';
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
  String contentKind = KnowledgeBaseContentKind.richText,
  String? fileName,
  String? fileMimeType,
  int? fileSizeBytes,
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
    contentKind: contentKind,
    fileName: fileName,
    fileMimeType: fileMimeType,
    fileSizeBytes: fileSizeBytes,
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
  String contentKind = KnowledgeBaseContentKind.richText,
  String? fileName,
  String? fileMimeType,
  int? fileSizeBytes,
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
    contentKind: contentKind,
    fileName: fileName,
    fileMimeType: fileMimeType,
    fileSizeBytes: fileSizeBytes,
    content: content ?? _defaultContent,
    targetRoleIds: targetRoleIds,
    targetDepartmentIds: targetDepartmentIds,
  );
}

/// An uploaded-file article (a PDF by default).
KnowledgeBaseArticle buildTestKnowledgeBaseFileArticle({
  String id = 'article-1',
  String title = 'Leave Policy',
  String fileName = 'Leave Policy.pdf',
  String fileMimeType = 'application/pdf',
  int fileSizeBytes = 2048,
  String visibilityType = KnowledgeBaseVisibility.everyone,
}) {
  return buildTestKnowledgeBaseArticle(
    id: id,
    title: title,
    content: const [],
    visibilityType: visibilityType,
    contentKind: KnowledgeBaseContentKind.file,
    fileName: fileName,
    fileMimeType: fileMimeType,
    fileSizeBytes: fileSizeBytes,
  );
}

KnowledgeBaseArticleVersionSummary buildTestKnowledgeBaseArticleVersionSummary({
  String id = 'version-1',
  int versionNumber = 1,
  String title = 'Onboarding SOP',
  String editorName = 'Jane Doe',
  DateTime? createdAt,
  String? fileName,
  String? fileMimeType,
  int? fileSizeBytes,
}) {
  return KnowledgeBaseArticleVersionSummary(
    id: id,
    versionNumber: versionNumber,
    title: title,
    editorName: editorName,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    fileName: fileName,
    fileMimeType: fileMimeType,
    fileSizeBytes: fileSizeBytes,
  );
}

KnowledgeBaseArticleVersion buildTestKnowledgeBaseArticleVersion({
  String id = 'version-1',
  int versionNumber = 1,
  String title = 'Onboarding SOP',
  String editorName = 'Jane Doe',
  DateTime? createdAt,
  dynamic content,
  String? fileName,
  String? fileMimeType,
  int? fileSizeBytes,
}) {
  return KnowledgeBaseArticleVersion(
    id: id,
    versionNumber: versionNumber,
    title: title,
    editorName: editorName,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    fileName: fileName,
    fileMimeType: fileMimeType,
    fileSizeBytes: fileSizeBytes,
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
    this.downloadError,
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

  /// Thrown by both file downloads when set.
  final Object? downloadError;

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

  // File-article calls.
  String? lastFileCreatedTitle;
  String? lastFileCreatedFileName;
  Uint8List? lastFileCreatedBytes;
  String? lastFileCreatedVisibilityType;
  List<String>? lastFileCreatedTargetRoleIds;
  String? lastReplacedId;
  String? lastReplacedFileName;
  String? lastReplacedTitle;
  bool? lastIncludeArchived;
  String? lastDownloadedArticleId;
  String? lastDownloadedVersionArticleId;
  String? lastDownloadedVersionId;

  /// What the download methods return.
  final Uint8List downloadedBytes = Uint8List.fromList([1, 2, 3]);

  @override
  Future<List<KnowledgeBaseArticleSummary>> getArticles({
    bool includeArchived = false,
  }) async {
    lastIncludeArchived = includeArchived;
    return includeArchived
        ? articles
        : articles.where((article) => !article.isArchived).toList();
  }

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
  Future<KnowledgeBaseArticle> createFileArticle({
    required String title,
    required Uint8List bytes,
    required String fileName,
    required String visibilityType,
    List<String>? targetRoleIds,
    List<String>? targetDepartmentIds,
  }) async {
    lastFileCreatedTitle = title;
    lastFileCreatedFileName = fileName;
    lastFileCreatedBytes = bytes;
    lastFileCreatedVisibilityType = visibilityType;
    lastFileCreatedTargetRoleIds = targetRoleIds;
    if (createArticleError != null) throw createArticleError!;
    return createArticleResult ??
        buildTestKnowledgeBaseFileArticle(title: title, fileName: fileName);
  }

  @override
  Future<KnowledgeBaseArticle> replaceArticleFile(
    String id, {
    required Uint8List bytes,
    required String fileName,
    String? title,
  }) async {
    lastReplacedId = id;
    lastReplacedFileName = fileName;
    lastReplacedTitle = title;
    if (updateArticleError != null) throw updateArticleError!;
    return updateArticleResult ??
        buildTestKnowledgeBaseFileArticle(id: id, fileName: fileName);
  }

  @override
  Future<Uint8List> downloadArticleFile(String articleId) async {
    lastDownloadedArticleId = articleId;
    if (downloadError != null) throw downloadError!;
    return downloadedBytes;
  }

  @override
  Future<Uint8List> downloadVersionFile(
    String articleId,
    String versionId,
  ) async {
    lastDownloadedVersionArticleId = articleId;
    lastDownloadedVersionId = versionId;
    if (downloadError != null) throw downloadError!;
    return downloadedBytes;
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
