import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/knowledge_base/application/knowledge_base_providers.dart';
import 'package:zera_erp/features/knowledge_base/presentation/pages/knowledge_base_version_history_page.dart';
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
      home: KnowledgeBaseVersionHistoryPage(articleId: 'article-1'),
    ),
  );
}

void main() {
  testWidgets('lists versions newest first, with editor and date', (
    tester,
  ) async {
    final repository = FakeKnowledgeBaseRepository(
      versionHistory: [
        buildTestKnowledgeBaseArticleVersionSummary(
          id: 'v1',
          versionNumber: 1,
          title: 'Onboarding SOP',
          editorName: 'Jane Doe',
          createdAt: DateTime(2026, 1, 1),
        ),
        buildTestKnowledgeBaseArticleVersionSummary(
          id: 'v2',
          versionNumber: 2,
          title: 'Onboarding SOP (updated)',
          editorName: 'Mona Manager',
          createdAt: DateTime(2026, 2, 1),
        ),
      ],
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    final version2Finder = find.text('Version 2 — Onboarding SOP (updated)');
    final version1Finder = find.text('Version 1 — Onboarding SOP');
    expect(version2Finder, findsOneWidget);
    expect(version1Finder, findsOneWidget);
    // Newest first: version 2's row appears above version 1's.
    expect(
      tester.getTopLeft(version2Finder).dy,
      lessThan(tester.getTopLeft(version1Finder).dy),
    );
    expect(find.text('Feb 01, 2026 by Mona Manager'), findsOneWidget);
  });

  testWidgets('shows an empty state when there is no version history', (
    tester,
  ) async {
    await tester.pumpWidget(_app(repository: FakeKnowledgeBaseRepository()));
    await tester.pumpAndSettle();

    expect(find.text('No version history yet.'), findsOneWidget);
  });

  testWidgets('tapping a version opens its read-only content', (
    tester,
  ) async {
    final repository = FakeKnowledgeBaseRepository(
      versionHistory: [
        buildTestKnowledgeBaseArticleVersionSummary(id: 'v1', versionNumber: 1),
      ],
      versionById: buildTestKnowledgeBaseArticleVersion(
        id: 'v1',
        versionNumber: 1,
        title: 'Onboarding SOP',
        content: {
          'ops': [
            {'insert': 'Old content.\n'},
          ],
        },
      ),
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Version 1'));
    await tester.pumpAndSettle();

    expect(find.text('Past Version'), findsOneWidget);
    final contentView = tester.widget<KnowledgeBaseContentView>(
      find.byType(KnowledgeBaseContentView),
    );
    expect(contentView.content, {
      'ops': [
        {'insert': 'Old content.\n'},
      ],
    });
  });
}
