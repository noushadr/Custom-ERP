import 'package:dio/dio.dart';
import '../models/knowledge_base_article_model.dart';
import '../models/knowledge_base_article_summary_model.dart';
import '../models/knowledge_base_article_version_model.dart';
import '../models/knowledge_base_article_version_summary_model.dart';

class KnowledgeBaseRemoteDataSource {
  const KnowledgeBaseRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<KnowledgeBaseArticleSummaryModel>> getArticles({
    bool includeArchived = false,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/knowledge-base',
      queryParameters: {'includeArchived': includeArchived.toString()},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(KnowledgeBaseArticleSummaryModel.fromJson)
        .toList();
  }

  Future<KnowledgeBaseArticleModel> getArticle(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/knowledge-base/$id',
    );
    return KnowledgeBaseArticleModel.fromJson(response.data!);
  }

  Future<List<KnowledgeBaseArticleVersionSummaryModel>> getVersionHistory(
    String articleId,
  ) async {
    final response = await _dio.get<List<dynamic>>(
      '/knowledge-base/$articleId/versions',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(KnowledgeBaseArticleVersionSummaryModel.fromJson)
        .toList();
  }

  Future<KnowledgeBaseArticleVersionModel> getVersion(
    String articleId,
    String versionId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/knowledge-base/$articleId/versions/$versionId',
    );
    return KnowledgeBaseArticleVersionModel.fromJson(response.data!);
  }

  Future<KnowledgeBaseArticleModel> createArticle({
    required String title,
    required dynamic content,
    required String visibilityType,
    List<String>? targetRoleIds,
    List<String>? targetDepartmentIds,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/knowledge-base',
      data: {
        'title': title,
        'content': content,
        'visibilityType': visibilityType,
        'targetRoleIds': ?targetRoleIds,
        'targetDepartmentIds': ?targetDepartmentIds,
      },
    );
    return KnowledgeBaseArticleModel.fromJson(response.data!);
  }

  Future<KnowledgeBaseArticleModel> updateArticle(
    String id, {
    String? title,
    dynamic content,
    String? visibilityType,
    List<String>? targetRoleIds,
    List<String>? targetDepartmentIds,
    bool? isArchived,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/knowledge-base/$id',
      data: {
        'title': ?title,
        'content': ?content,
        'visibilityType': ?visibilityType,
        'targetRoleIds': ?targetRoleIds,
        'targetDepartmentIds': ?targetDepartmentIds,
        'isArchived': ?isArchived,
      },
    );
    return KnowledgeBaseArticleModel.fromJson(response.data!);
  }
}
