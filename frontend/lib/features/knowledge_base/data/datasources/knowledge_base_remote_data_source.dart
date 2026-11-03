import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../domain/entities/knowledge_base_upload_file.dart';
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

  /// Every file goes in under the same `files` field name — what the
  /// backend's multi-file upload expects (a map entry per file would be
  /// renamed `files[]` by Dio).
  void _addFiles(FormData form, List<KnowledgeBaseUploadFile> files) {
    for (final file in files) {
      form.files.add(
        MapEntry(
          'files',
          MultipartFile.fromBytes(file.bytes, filename: file.fileName),
        ),
      );
    }
  }

  Future<KnowledgeBaseArticleModel> createFileArticle({
    required String title,
    required List<KnowledgeBaseUploadFile> files,
    required String visibilityType,
    List<String>? targetRoleIds,
    List<String>? targetDepartmentIds,
  }) async {
    final form = FormData.fromMap({
      'title': title,
      'visibilityType': visibilityType,
      // Repeated fields (one per id) — the backend normalises a single
      // value and a list the same way.
      'targetRoleIds': ?targetRoleIds,
      'targetDepartmentIds': ?targetDepartmentIds,
    });
    _addFiles(form, files);
    final response = await _dio.post<Map<String, dynamic>>(
      '/knowledge-base/file-article',
      data: form,
    );
    return KnowledgeBaseArticleModel.fromJson(response.data!);
  }

  Future<KnowledgeBaseArticleModel> replaceArticleFiles(
    String id, {
    required List<KnowledgeBaseUploadFile> files,
    String? title,
  }) async {
    final form = FormData.fromMap({'title': ?title});
    _addFiles(form, files);
    final response = await _dio.put<Map<String, dynamic>>(
      '/knowledge-base/$id/files',
      data: form,
    );
    return KnowledgeBaseArticleModel.fromJson(response.data!);
  }

  Future<Uint8List> downloadArticleFile(String articleId, int index) =>
      _downloadBytes('/knowledge-base/$articleId/files/$index');

  Future<Uint8List> downloadVersionFile(
    String articleId,
    String versionId,
    int index,
  ) => _downloadBytes(
    '/knowledge-base/$articleId/versions/$versionId/files/$index',
  );

  Future<Uint8List> _downloadBytes(String path) async {
    final response = await _dio.get<List<int>>(
      path,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
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
