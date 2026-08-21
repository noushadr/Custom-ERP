import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../application/knowledge_base_providers.dart';
import '../../domain/entities/knowledge_base_article.dart';
import '../widgets/knowledge_base_content_view.dart';
import 'knowledge_base_editor_page.dart';
import 'knowledge_base_version_history_page.dart';

/// Reads one article's current content. Anyone who can see it in the list
/// can open it — the backend has already applied the visibility check by
/// the time this page's fetch succeeds; a 403 renders as the same "could
/// not load" state as any other failure, since the list never shows an
/// article a viewer can't open in the first place.
class KnowledgeBaseArticlePage extends ConsumerWidget {
  const KnowledgeBaseArticlePage({super.key, required this.articleId});

  final String articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleAsync = ref.watch(knowledgeBaseArticleProvider(articleId));
    final authState = ref.watch(authControllerProvider);
    final canManage =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('knowledge_base.manage');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    KnowledgeBaseVersionHistoryPage(articleId: articleId),
              ),
            ),
            icon: const Icon(Icons.history, size: 18),
            label: const Text('Version History'),
          ),
          if (canManage)
            articleAsync.maybeWhen(
              data: (article) => TextButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          KnowledgeBaseEditorPage(existingArticle: article),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: articleAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Could not load this article.'),
            ),
            data: (article) => _ArticleBody(article: article),
          ),
        ),
      ),
    );
  }
}

class _ArticleBody extends StatelessWidget {
  const _ArticleBody({required this.article});

  final KnowledgeBaseArticle article;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(article.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              Text(
                'By ${article.authorName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Published ${formatDisplayDateOnly(article.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Last updated ${formatDisplayDateOnly(article.updatedAt)} by ${article.lastEditedByName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: 20),
          KnowledgeBaseContentView(content: article.content),
        ],
      ),
    );
  }
}
