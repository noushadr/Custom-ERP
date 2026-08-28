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
