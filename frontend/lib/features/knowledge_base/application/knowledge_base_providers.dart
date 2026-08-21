import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/knowledge_base_remote_data_source.dart';
import '../data/repositories/knowledge_base_repository_impl.dart';
import '../domain/entities/knowledge_base_article.dart';
import '../domain/entities/knowledge_base_article_summary.dart';
import '../domain/entities/knowledge_base_article_version.dart';
import '../domain/entities/knowledge_base_article_version_summary.dart';
import '../domain/repositories/knowledge_base_repository.dart';

final knowledgeBaseRemoteDataSourceProvider =
    Provider<KnowledgeBaseRemoteDataSource>(
      (ref) => KnowledgeBaseRemoteDataSource(ref.watch(dioClientProvider).dio),
    );

final knowledgeBaseRepositoryProvider = Provider<KnowledgeBaseRepository>(
  (ref) => KnowledgeBaseRepositoryImpl(
    ref.watch(knowledgeBaseRemoteDataSourceProvider),
  ),
);

// Every provider below re-watches authControllerProvider purely to create a
// dependency edge, so switching identity (impersonate/returnToAdmin/logout)
// triggers a refetch — see the longer explanation in employee_providers.dart.

final knowledgeBaseArticlesProvider = FutureProvider.autoDispose
    .family<List<KnowledgeBaseArticleSummary>, bool>((ref, includeArchived) {
      ref.watch(authControllerProvider);
      return ref
          .watch(knowledgeBaseRepositoryProvider)
          .getArticles(includeArchived: includeArchived);
    });

final knowledgeBaseArticleProvider = FutureProvider.autoDispose
    .family<KnowledgeBaseArticle, String>((ref, id) {
      ref.watch(authControllerProvider);
      return ref.watch(knowledgeBaseRepositoryProvider).getArticle(id);
    });

final knowledgeBaseVersionHistoryProvider = FutureProvider.autoDispose
    .family<List<KnowledgeBaseArticleVersionSummary>, String>((
      ref,
      articleId,
    ) {
      ref.watch(authControllerProvider);
      return ref
          .watch(knowledgeBaseRepositoryProvider)
          .getVersionHistory(articleId);
    });

final knowledgeBaseVersionProvider = FutureProvider.autoDispose
    .family<KnowledgeBaseArticleVersion, (String articleId, String versionId)>(
      (ref, params) {
        ref.watch(authControllerProvider);
        return ref
            .watch(knowledgeBaseRepositoryProvider)
            .getVersion(params.$1, params.$2);
      },
    );
