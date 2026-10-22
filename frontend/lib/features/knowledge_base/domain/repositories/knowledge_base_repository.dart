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

  /// Requires `knowledge_base.manage`. Creates an article whose body is the
  /// uploaded file instead of written text; the same title/visibility
  /// targeting rules apply.
  Future<KnowledgeBaseArticle> createFileArticle({
    required String title,
    required Uint8List bytes,
    required String fileName,
    required String visibilityType,
    List<String>? targetRoleIds,
    List<String>? targetDepartmentIds,
  });

  /// Requires `knowledge_base.manage`. Swaps a file article's file for a new
  /// one, recording a new version (the old file stays openable from history).
  Future<KnowledgeBaseArticle> replaceArticleFile(
    String id, {
    required Uint8List bytes,
    required String fileName,
    String? title,
  });

  /// The article's current uploaded file, fetched through the authenticated
  /// API (uploaded files are never reachable by URL alone).
  Future<Uint8List> downloadArticleFile(String articleId);

  /// A past version's own file.
  Future<Uint8List> downloadVersionFile(String articleId, String versionId);

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
