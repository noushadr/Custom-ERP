import 'dart:typed_data';
import 'package:zera_erp/features/knowledge_base/domain/entities/knowledge_base_article.dart';
import 'package:zera_erp/features/knowledge_base/domain/entities/knowledge_base_article_summary.dart';
import 'package:zera_erp/features/knowledge_base/domain/entities/knowledge_base_article_version.dart';
import 'package:zera_erp/features/knowledge_base/domain/entities/knowledge_base_article_version_summary.dart';
import 'package:zera_erp/features/knowledge_base/domain/entities/knowledge_base_content_kind.dart';
import 'package:zera_erp/features/knowledge_base/domain/entities/knowledge_base_file_info.dart';
import 'package:zera_erp/features/knowledge_base/domain/entities/knowledge_base_upload_file.dart';
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
  List<KnowledgeBaseFileInfo>? files,
  List<String> targetRoleNames = const [],
  List<String> targetDepartmentNames = const [],
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
    files: files ?? _oneFile(fileName, fileMimeType, fileSizeBytes),
    targetRoleNames: targetRoleNames,
    targetDepartmentNames: targetDepartmentNames,
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
  List<KnowledgeBaseFileInfo>? files,
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
    files: files ?? _oneFile(fileName, fileMimeType, fileSizeBytes),
    content: content ?? _defaultContent,
    targetRoleIds: targetRoleIds,
    targetDepartmentIds: targetDepartmentIds,
  );
}

/// One file's worth of `files` from the old single-file test arguments.
List<KnowledgeBaseFileInfo> _oneFile(
  String? fileName,
  String? fileMimeType,
  int? fileSizeBytes,
) => fileName == null
    ? const []
    : [
        KnowledgeBaseFileInfo(
          fileName: fileName,
          mimeType: fileMimeType ?? 'application/pdf',
          sizeBytes: fileSizeBytes ?? 0,
        ),
      ];

/// An uploaded-file article (a PDF by default).
KnowledgeBaseArticle buildTestKnowledgeBaseFileArticle({
  String id = 'article-1',
  String title = 'Leave Policy',
  String fileName = 'Leave Policy.pdf',
  String fileMimeType = 'application/pdf',
  int fileSizeBytes = 2048,
  String visibilityType = KnowledgeBaseVisibility.everyone,
  List<KnowledgeBaseFileInfo>? files,
}) {
  return buildTestKnowledgeBaseArticle(
    id: id,
    title: title,
    content: const [],
    visibilityType: visibilityType,
    contentKind: KnowledgeBaseContentKind.file,
    files: files ?? _oneFile(fileName, fileMimeType, fileSizeBytes),
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
  List<KnowledgeBaseFileInfo>? files,
}) {
  return KnowledgeBaseArticleVersionSummary(
    id: id,
    versionNumber: versionNumber,
    title: title,
    editorName: editorName,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    files: files ?? _oneFile(fileName, fileMimeType, fileSizeBytes),
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
  List<KnowledgeBaseFileInfo>? files,
}) {
  return KnowledgeBaseArticleVersion(
    id: id,
    versionNumber: versionNumber,
    title: title,
    editorName: editorName,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    files: files ?? _oneFile(fileName, fileMimeType, fileSizeBytes),
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
  List<String>? lastFileCreatedFileNames;
  List<String>? lastReplacedFileNames;
  int? lastDownloadedFileIndex;
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
    required List<KnowledgeBaseUploadFile> files,
    required String visibilityType,
    List<String>? targetRoleIds,
    List<String>? targetDepartmentIds,
  }) async {
    lastFileCreatedTitle = title;
    lastFileCreatedFileNames = [for (final f in files) f.fileName];
    lastFileCreatedFileName = files.first.fileName;
    lastFileCreatedBytes = files.first.bytes;
    lastFileCreatedVisibilityType = visibilityType;
    lastFileCreatedTargetRoleIds = targetRoleIds;
    if (createArticleError != null) throw createArticleError!;
    return createArticleResult ??
        buildTestKnowledgeBaseFileArticle(
          title: title,
          fileName: files.first.fileName,
        );
  }

  @override
  Future<KnowledgeBaseArticle> replaceArticleFiles(
    String id, {
    required List<KnowledgeBaseUploadFile> files,
    String? title,
  }) async {
    lastReplacedId = id;
    lastReplacedFileNames = [for (final f in files) f.fileName];
    lastReplacedFileName = files.first.fileName;
    lastReplacedTitle = title;
    if (updateArticleError != null) throw updateArticleError!;
    return updateArticleResult ??
        buildTestKnowledgeBaseFileArticle(
          id: id,
          fileName: files.first.fileName,
        );
  }

  @override
  Future<Uint8List> downloadArticleFile(String articleId, int index) async {
    lastDownloadedArticleId = articleId;
    lastDownloadedFileIndex = index;
    if (downloadError != null) throw downloadError!;
    return downloadedBytes;
  }

  @override
  Future<Uint8List> downloadVersionFile(
    String articleId,
    String versionId,
    int index,
  ) async {
    lastDownloadedFileIndex = index;
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
