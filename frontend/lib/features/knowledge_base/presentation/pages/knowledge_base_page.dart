import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../application/knowledge_base_providers.dart';
import '../../domain/entities/knowledge_base_article_summary.dart';
import 'knowledge_base_article_page.dart';
import 'knowledge_base_editor_page.dart';

/// The company wiki's home page: a single flat list of every article
/// (company-internal scale, same reasoning as the Employee Directory and
/// Notices lists not paginating either).
class KnowledgeBasePage extends ConsumerWidget {
  const KnowledgeBasePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(knowledgeBaseArticlesProvider(false));
    final authState = ref.watch(authControllerProvider);
    final canManage =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('knowledge_base.manage');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (canManage) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const KnowledgeBaseEditorPage(),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Article'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: articlesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text(
                      'Could not load the knowledge base. Please try again.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  data: (articles) => _KnowledgeBaseBody(articles: articles),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KnowledgeBaseBody extends StatelessWidget {
  const _KnowledgeBaseBody({required this.articles});

  final List<KnowledgeBaseArticleSummary> articles;

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) {
      return const Center(
        child: Text('No articles have been published yet.'),
      );
    }

    final sortedArticles = [...articles]
      ..sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );

    return SingleChildScrollView(
      child: FormSection(
        title: 'All Articles',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < sortedArticles.length; i++) ...[
              _ArticleRow(article: sortedArticles[i]),
              if (i < sortedArticles.length - 1)
                const Divider(height: 20, color: AppColors.borderSubtle),
            ],
          ],
        ),
      ),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  const _ArticleRow({required this.article});

  final KnowledgeBaseArticleSummary article;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => KnowledgeBaseArticlePage(articleId: article.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Posted by ${article.authorName} · '
                    'Created ${formatDisplayDateOnly(article.createdAt)} · '
                    'Updated ${formatDisplayDateOnly(article.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
