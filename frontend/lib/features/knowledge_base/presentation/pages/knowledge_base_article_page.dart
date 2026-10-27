import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../application/knowledge_base_providers.dart';
import '../../domain/entities/knowledge_base_article.dart';
import '../widgets/knowledge_base_content_view.dart';
import '../widgets/knowledge_base_file_card.dart';
import '../../domain/exceptions/knowledge_base_exception.dart';
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
          if (canManage)
            articleAsync.maybeWhen(
              data: (article) => TextButton.icon(
                onPressed: () => _toggleArchive(context, ref, article),
                icon: Icon(
                  article.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                  size: 18,
                ),
                label: Text(article.isArchived ? 'Unarchive' : 'Archive'),
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

/// Archiving hides an article from everyone but managers (who can show
/// archived ones on the list) without deleting it or its version history;
/// unarchiving puts it straight back.
Future<void> _toggleArchive(
  BuildContext context,
  WidgetRef ref,
  KnowledgeBaseArticle article,
) async {
  final archiving = !article.isArchived;
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  if (archiving) {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive article?'),
        content: Text(
          '"${article.title}" will be hidden from everyone except people who '
          'manage the knowledge base. You can unarchive it any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
  }
  try {
    await ref
        .read(knowledgeBaseRepositoryProvider)
        .updateArticle(article.id, isArchived: archiving);
    ref.invalidate(knowledgeBaseArticlesProvider);
    ref.invalidate(knowledgeBaseArticleProvider(article.id));
    messenger.showSnackBar(
      SnackBar(
        content: Text(archiving ? 'Article archived.' : 'Article unarchived.'),
      ),
    );
    if (archiving) navigator.pop();
  } on KnowledgeBaseException catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.message)));
  }
}

class _ArticleBody extends ConsumerWidget {
  const _ArticleBody({required this.article});

  final KnowledgeBaseArticle article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                'Published ${formatDisplayDateOnly(article.createdAt)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                'Last updated ${formatDisplayDateOnly(article.updatedAt)} by ${article.lastEditedByName}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: 20),
          if (article.isFile && article.fileName != null)
            KnowledgeBaseFileCard(
              fileName: article.fileName!,
              mimeType: article.fileMimeType,
              sizeBytes: article.fileSizeBytes,
              load: () => ref
                  .read(knowledgeBaseRepositoryProvider)
                  .downloadArticleFile(article.id),
            )
          else
            KnowledgeBaseContentView(content: article.content),
        ],
      ),
    );
  }
}
