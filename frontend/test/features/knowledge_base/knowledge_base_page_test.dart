import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/knowledge_base/application/knowledge_base_providers.dart';
import 'package:zera_erp/features/knowledge_base/domain/entities/knowledge_base_visibility.dart';
import 'package:zera_erp/features/knowledge_base/presentation/pages/knowledge_base_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_knowledge_base.dart';

Widget _app({FakeKnowledgeBaseRepository? repository}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(const AuthAuthenticated(testAuthUser)),
      ),
      knowledgeBaseRepositoryProvider.overrideWithValue(
        repository ?? FakeKnowledgeBaseRepository(),
      ),
    ],
    child: const MaterialApp(home: KnowledgeBasePage()),
  );
}

void main() {
  testWidgets('shows a single flat list of all articles with posting info', (
    tester,
  ) async {
    final repository = FakeKnowledgeBaseRepository(
      articles: [
        buildTestKnowledgeBaseArticleSummary(
          id: 'article-1',
          title: 'Onboarding SOP',
          createdAt: DateTime(2026, 3, 1),
          updatedAt: DateTime(2026, 3, 1),
        ),
        buildTestKnowledgeBaseArticleSummary(
          id: 'article-2',
          title: 'Expense Policy',
          authorName: 'HR Team',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 4, 1),
        ),
      ],
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Recently Published'), findsNothing);
    expect(find.text('Recently Updated'), findsNothing);
    expect(find.text('All Articles'), findsOneWidget);
    expect(find.text('Onboarding SOP'), findsWidgets);
    expect(find.text('Expense Policy'), findsWidgets);
    expect(
      find.text(
        'Posted by HR Team · Created Jan 01, 2026 · Updated Apr 01, 2026',
      ),
      findsOneWidget,
    );
  });

  testWidgets('each row says who the article is visible to', (tester) async {
    final repository = FakeKnowledgeBaseRepository(
      articles: [
        buildTestKnowledgeBaseArticleSummary(id: 'a1', title: 'For all'),
        buildTestKnowledgeBaseArticleSummary(
          id: 'a2',
          title: 'SEO only',
          visibilityType: KnowledgeBaseVisibility.departments,
          targetDepartmentNames: const ['SEO', 'Design'],
        ),
        buildTestKnowledgeBaseArticleSummary(
          id: 'a3',
          title: 'Leads only',
          visibilityType: KnowledgeBaseVisibility.roles,
          targetRoleNames: const ['Team Lead'],
        ),
        buildTestKnowledgeBaseArticleSummary(
          id: 'a4',
          title: 'Mixed',
          visibilityType: KnowledgeBaseVisibility.rolesAndDepartments,
          targetRoleNames: const ['HR/Manager'],
          targetDepartmentNames: const ['SEO'],
        ),
      ],
    );
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Visible to: Everyone'), findsOneWidget);
    expect(find.text('Visible to: Departments: SEO, Design'), findsOneWidget);
    expect(find.text('Visible to: Roles: Team Lead'), findsOneWidget);
    expect(
      find.text('Visible to: Hybrid — Roles: HR/Manager + Departments: SEO'),
      findsOneWidget,
    );
  });

  testWidgets('shows an empty state when no articles exist', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('No articles have been published yet.'), findsOneWidget);
  });

  testWidgets('tapping an article row opens the article page', (tester) async {
    final repository = FakeKnowledgeBaseRepository(
      articles: [
        buildTestKnowledgeBaseArticleSummary(
          id: 'article-1',
          title: 'Onboarding SOP',
        ),
      ],
      articleById: buildTestKnowledgeBaseArticle(
        id: 'article-1',
        title: 'Onboarding SOP',
      ),
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Onboarding SOP').first);
    await tester.pumpAndSettle();

    // Navigating to the article page is what this test verifies; the
    // article page's own test covers that its content is correctly passed
    // to the Quill viewer.
    expect(find.text('Article'), findsOneWidget);
  });
}
