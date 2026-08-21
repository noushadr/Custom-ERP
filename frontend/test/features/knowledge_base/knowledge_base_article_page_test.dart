import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/knowledge_base/application/knowledge_base_providers.dart';
import 'package:zera_erp/features/knowledge_base/presentation/pages/knowledge_base_article_page.dart';
import 'package:zera_erp/features/knowledge_base/presentation/widgets/knowledge_base_content_view.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_knowledge_base.dart';

Widget _app({required FakeKnowledgeBaseRepository repository}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(const AuthAuthenticated(testAuthUser)),
      ),
      knowledgeBaseRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(
      home: KnowledgeBaseArticlePage(articleId: 'article-1'),
    ),
  );
}

void main() {
  testWidgets('shows the title, author, dates, and content', (tester) async {
    final repository = FakeKnowledgeBaseRepository(
      articleById: buildTestKnowledgeBaseArticle(
        id: 'article-1',
        title: 'Onboarding SOP',
        authorName: 'Jane Doe',
        lastEditedByName: 'Mona Manager',
        createdAt: DateTime(2026, 1, 5),
        updatedAt: DateTime(2026, 2, 10),
        content: {
          'ops': [
            {'insert': 'Welcome to the team.\n'},
          ],
        },
      ),
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Onboarding SOP'), findsOneWidget);
    expect(find.text('By Jane Doe'), findsOneWidget);
    expect(find.text('Published Jan 05, 2026'), findsOneWidget);
    expect(find.text('Last updated Feb 10, 2026 by Mona Manager'), findsOneWidget);
    // The Quill viewer renders the delta through its own internal
    // RenderObject tree rather than plain Text/RichText widgets, so verify
    // the right content was handed to it rather than the rendered pixels.
    final contentView = tester.widget<KnowledgeBaseContentView>(
      find.byType(KnowledgeBaseContentView),
    );
    expect(contentView.content, {
      'ops': [
        {'insert': 'Welcome to the team.\n'},
      ],
    });
  });

  testWidgets('shows an error message when the article fails to load', (
    tester,
  ) async {
    final repository = FakeKnowledgeBaseRepository(
      getArticleError: Exception('boom'),
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Could not load this article.'), findsOneWidget);
  });
}
