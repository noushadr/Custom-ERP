import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../application/knowledge_base_providers.dart';
import '../../domain/entities/knowledge_base_article_version_summary.dart';
import 'knowledge_base_version_page.dart';

/// Every past version of an article — who changed it and when. Visible to
/// anyone who can already view the article itself, not gated further by
/// `knowledge_base.manage`.
class KnowledgeBaseVersionHistoryPage extends ConsumerWidget {
  const KnowledgeBaseVersionHistoryPage({super.key, required this.articleId});

  final String articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionsAsync = ref.watch(
      knowledgeBaseVersionHistoryProvider(articleId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Version History')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: versionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Could not load the version history.'),
            ),
            data: (versions) =>
                _VersionList(articleId: articleId, versions: versions),
          ),
        ),
      ),
    );
  }
}

class _VersionList extends StatelessWidget {
  const _VersionList({required this.articleId, required this.versions});

  final String articleId;
  final List<KnowledgeBaseArticleVersionSummary> versions;

  @override
  Widget build(BuildContext context) {
    if (versions.isEmpty) {
      return const Center(child: Text('No version history yet.'));
    }

    final sorted = [...versions]
      ..sort((a, b) => b.versionNumber.compareTo(a.versionNumber));

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: sorted.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 20, color: AppColors.borderSubtle),
      itemBuilder: (context, index) {
        final version = sorted[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Version ${version.versionNumber} — ${version.title}'),
          subtitle: Text(
            '${formatDisplayDateOnly(version.createdAt)} by ${version.editorName}',
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => KnowledgeBaseVersionPage(
                articleId: articleId,
                versionId: version.id,
              ),
            ),
          ),
        );
      },
    );
  }
}
