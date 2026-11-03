import '../entities/knowledge_base_upload_file.dart';
import 'dart:typed_data';
import '../entities/knowledge_base_article.dart';
import '../entities/knowledge_base_article_summary.dart';
import '../entities/knowledge_base_article_version.dart';
import '../entities/knowledge_base_article_version_summary.dart';

abstract interface class KnowledgeBaseRepository {
  /// `includeArchived` is honored only for `knowledge_base.manage` holders;
  /// everyone else always sees only non-archived, visibility-filtered
  /// articles regardless of the flag.
  Future<List<KnowledgeBaseArticleSummary>> getArticles({
    bool includeArchived = false,
  });

  /// Throws [KnowledgeBaseException] if the caller isn't allowed to view
  /// this article.
  Future<KnowledgeBaseArticle> getArticle(String id);

  Future<List<KnowledgeBaseArticleVersionSummary>> getVersionHistory(
    String articleId,
  );

  Future<KnowledgeBaseArticleVersion> getVersion(
    String articleId,
    String versionId,
  );

  /// Requires `knowledge_base.manage`.
  Future<KnowledgeBaseArticle> createArticle({
    required String title,
    required dynamic content,
    required String visibilityType,
    List<String>? targetRoleIds,
    List<String>? targetDepartmentIds,
  });

  /// Requires `knowledge_base.manage`. Creates an article whose body is 1-3
  /// uploaded files instead of written text; the same title/visibility
  /// targeting rules apply.
  Future<KnowledgeBaseArticle> createFileArticle({
    required String title,
    required List<KnowledgeBaseUploadFile> files,
    required String visibilityType,
    List<String>? targetRoleIds,
    List<String>? targetDepartmentIds,
  });

  /// Requires `knowledge_base.manage`. Swaps a file article's files for a new
  /// set of 1-3, recording a new version (the old files stay openable from
  /// history).
  Future<KnowledgeBaseArticle> replaceArticleFiles(
    String id, {
    required List<KnowledgeBaseUploadFile> files,
    String? title,
  });

  /// One of the article's current uploaded files (by position), fetched
  /// through the authenticated API (uploaded files are never reachable by URL
  /// alone).
  Future<Uint8List> downloadArticleFile(String articleId, int index);

  /// One file of a past version.
  Future<Uint8List> downloadVersionFile(
    String articleId,
    String versionId,
    int index,
  );

  /// Requires `knowledge_base.manage`.
  Future<KnowledgeBaseArticle> updateArticle(
    String id, {
    String? title,
    dynamic content,
    String? visibilityType,
    List<String>? targetRoleIds,
    List<String>? targetDepartmentIds,
    bool? isArchived,
  });
}
