import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../application/knowledge_base_providers.dart';
import '../widgets/knowledge_base_content_view.dart';

/// A single past version's content — read-only, exactly as it was saved at
/// that point. No restore/rollback action, since editing always builds on
/// the current live content, not a selected historical one.
class KnowledgeBaseVersionPage extends ConsumerWidget {
  const KnowledgeBaseVersionPage({
    super.key,
    required this.articleId,
    required this.versionId,
  });

  final String articleId;
  final String versionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(
      knowledgeBaseVersionProvider((articleId, versionId)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Past Version')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: versionAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Could not load this version.'),
            ),
            data: (version) => SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    version.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version ${version.versionNumber} · ${formatDisplayDateOnly(version.createdAt)} by ${version.editorName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.borderSubtle),
                  const SizedBox(height: 20),
                  KnowledgeBaseContentView(content: version.content),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
