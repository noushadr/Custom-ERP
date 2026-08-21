import 'package:dio/dio.dart';
import '../../domain/entities/knowledge_base_article.dart';
import '../../domain/entities/knowledge_base_article_summary.dart';
import '../../domain/entities/knowledge_base_article_version.dart';
import '../../domain/entities/knowledge_base_article_version_summary.dart';
import '../../domain/exceptions/knowledge_base_exception.dart';
import '../../domain/repositories/knowledge_base_repository.dart';
import '../datasources/knowledge_base_remote_data_source.dart';

class KnowledgeBaseRepositoryImpl implements KnowledgeBaseRepository {
  const KnowledgeBaseRepositoryImpl(this._remoteDataSource);

  final KnowledgeBaseRemoteDataSource _remoteDataSource;

  @override
  Future<List<KnowledgeBaseArticleSummary>> getArticles({
    bool includeArchived = false,
  }) => _guard(
    () => _remoteDataSource.getArticles(includeArchived: includeArchived),
  );

  @override
  Future<KnowledgeBaseArticle> getArticle(String id) =>
      _guard(() => _remoteDataSource.getArticle(id));

  @override
  Future<List<KnowledgeBaseArticleVersionSummary>> getVersionHistory(
    String articleId,
  ) => _guard(() => _remoteDataSource.getVersionHistory(articleId));

  @override
  Future<KnowledgeBaseArticleVersion> getVersion(
    String articleId,
    String versionId,
  ) => _guard(() => _remoteDataSource.getVersion(articleId, versionId));

  @override
  Future<KnowledgeBaseArticle> createArticle({
    required String title,
    required dynamic content,
    required String visibilityType,
    List<String>? targetRoleIds,
    List<String>? targetDepartmentIds,
  }) => _guard(
    () => _remoteDataSource.createArticle(
      title: title,
      content: content,
      visibilityType: visibilityType,
      targetRoleIds: targetRoleIds,
      targetDepartmentIds: targetDepartmentIds,
    ),
  );

  @override
  Future<KnowledgeBaseArticle> updateArticle(
    String id, {
    String? title,
    dynamic content,
    String? visibilityType,
    List<String>? targetRoleIds,
    List<String>? targetDepartmentIds,
    bool? isArchived,
  }) => _guard(
    () => _remoteDataSource.updateArticle(
      id,
      title: title,
      content: content,
      visibilityType: visibilityType,
      targetRoleIds: targetRoleIds,
      targetDepartmentIds: targetDepartmentIds,
      isArchived: isArchived,
    ),
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw KnowledgeBaseException(_mapError(error));
    }
  }

  String _mapError(DioException error) {
    final status = error.response?.statusCode;
    if (status == 400) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (data is Map && data['message'] is List) {
        return (data['message'] as List).join(', ');
      }
      return 'Invalid request.';
    }
    if (status == 403) return "You don't have permission to do that.";
    if (status == 404) return 'That could not be found.';
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
