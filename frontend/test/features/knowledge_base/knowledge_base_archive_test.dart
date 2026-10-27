import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/knowledge_base/application/knowledge_base_providers.dart';
import 'package:zera_erp/features/knowledge_base/presentation/pages/knowledge_base_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_knowledge_base.dart';

const _manager = AuthUser(
  id: 'user-1',
  email: 'hr@zeracreative.com',
  role: 'HR/Manager',
  permissions: ['knowledge_base.manage'],
);

Widget _app(FakeKnowledgeBaseRepository repository, {AuthUser? user}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(user ?? testAuthUser)),
      ),
      knowledgeBaseRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(home: Scaffold(body: KnowledgeBasePage())),
  );
}

FakeKnowledgeBaseRepository _repository() => FakeKnowledgeBaseRepository(
  articles: [
    buildTestKnowledgeBaseArticleSummary(id: 'live', title: 'Live Article'),
    buildTestKnowledgeBaseArticleSummary(
      id: 'old',
      title: 'Old Article',
      isArchived: true,
    ),
  ],
  articleById: buildTestKnowledgeBaseArticle(id: 'live', title: 'Live Article'),
);

void main() {
  testWidgets('a manager can show archived articles, marked as Archived', (
    tester,
  ) async {
    final repository = _repository();
    await tester.pumpWidget(_app(repository, user: _manager));
    await tester.pumpAndSettle();

    expect(find.text('Old Article'), findsNothing);
    expect(find.text('Archived'), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(repository.lastIncludeArchived, isTrue);
    expect(find.text('Old Article'), findsOneWidget);
    expect(find.text('Archived'), findsOneWidget);
  });

  testWidgets('staff get no archive switch and never see archived articles', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_repository()));
    await tester.pumpAndSettle();

    expect(find.byType(Switch), findsNothing);
    expect(find.text('Old Article'), findsNothing);
  });

  testWidgets('a manager archives an article after confirming', (tester) async {
    final repository = _repository();
    await tester.pumpWidget(_app(repository, user: _manager));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Live Article'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(find.text('Archive article?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Archive'));
    await tester.pumpAndSettle();

    expect(repository.lastUpdatedId, 'live');
    expect(repository.lastUpdatedIsArchived, isTrue);
    expect(find.text('Article archived.'), findsOneWidget);
  });

  testWidgets('cancelling the confirmation archives nothing', (tester) async {
    final repository = _repository();
    await tester.pumpWidget(_app(repository, user: _manager));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Live Article'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.lastUpdatedId, isNull);
  });

  testWidgets('an archived article offers Unarchive, with no confirmation', (
    tester,
  ) async {
    final repository = FakeKnowledgeBaseRepository(
      articles: [
        buildTestKnowledgeBaseArticleSummary(
          id: 'old',
          title: 'Old Article',
          isArchived: true,
        ),
      ],
      articleById: buildTestKnowledgeBaseArticle(
        id: 'old',
        title: 'Old Article',
        isArchived: true,
      ),
    );
    await tester.pumpWidget(_app(repository, user: _manager));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Old Article'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unarchive'));
    await tester.pumpAndSettle();

    expect(repository.lastUpdatedIsArchived, isFalse);
    expect(find.text('Article unarchived.'), findsOneWidget);
  });
}
