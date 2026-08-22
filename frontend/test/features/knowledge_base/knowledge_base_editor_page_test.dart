import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/application/role_providers.dart';
import 'package:zera_erp/features/authentication/domain/entities/role.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/entities/department.dart';
import 'package:zera_erp/features/knowledge_base/application/knowledge_base_providers.dart';
import 'package:zera_erp/features/knowledge_base/domain/entities/knowledge_base_visibility.dart';
import 'package:zera_erp/features/knowledge_base/presentation/pages/knowledge_base_editor_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_knowledge_base.dart';

Future<void> _useTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app({
  required Widget child,
  FakeKnowledgeBaseRepository? repository,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(const AuthAuthenticated(testAuthUser)),
      ),
      knowledgeBaseRepositoryProvider.overrideWithValue(
        repository ?? FakeKnowledgeBaseRepository(),
      ),
      rolesProvider.overrideWith(
        (ref) async => const [
          Role(
            id: 'role-team-lead',
            name: 'Team Lead',
            isSystem: true,
            permissions: [],
            userCount: 3,
          ),
        ],
      ),
      departmentsProvider.overrideWith(
        (ref) async => const [Department(id: 'dept-eng', name: 'Engineering')],
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: child,
    ),
  );
}

void main() {
  testWidgets('requires a title before saving', (tester) async {
    await _useTallSurface(tester);
    final repository = FakeKnowledgeBaseRepository();

    await tester.pumpWidget(
      _app(child: const KnowledgeBaseEditorPage(), repository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsOneWidget);
    expect(repository.lastCreatedTitle, isNull);
  });

  testWidgets(
    'requires at least one role when visibility is Specific roles',
    (tester) async {
      await _useTallSurface(tester);
      final repository = FakeKnowledgeBaseRepository();

      await tester.pumpWidget(
        _app(child: const KnowledgeBaseEditorPage(), repository: repository),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'SOP Title');
      await tester.tap(find.text('Specific roles'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publish'));
      await tester.pumpAndSettle();

      expect(
        find.text('Select at least one role for this visibility type.'),
        findsOneWidget,
      );
      expect(repository.lastCreatedTitle, isNull);
    },
  );

  testWidgets('creates an Everyone-visibility article', (tester) async {
    await _useTallSurface(tester);
    final repository = FakeKnowledgeBaseRepository();

    await tester.pumpWidget(
      _app(child: const KnowledgeBaseEditorPage(), repository: repository),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Onboarding SOP');
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    expect(repository.lastCreatedTitle, 'Onboarding SOP');
    expect(
      repository.lastCreatedVisibilityType,
      KnowledgeBaseVisibility.everyone,
    );
    expect(repository.lastCreatedTargetRoleIds, isEmpty);
  });

  testWidgets(
    'creates a roles-targeted article with the selected role id',
    (tester) async {
      await _useTallSurface(tester);
      final repository = FakeKnowledgeBaseRepository();

      await tester.pumpWidget(
        _app(child: const KnowledgeBaseEditorPage(), repository: repository),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Leave Policy');
      await tester.tap(find.text('Specific roles'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Team Lead'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publish'));
      await tester.pumpAndSettle();

      expect(repository.lastCreatedTitle, 'Leave Policy');
      expect(
        repository.lastCreatedVisibilityType,
        KnowledgeBaseVisibility.roles,
      );
      expect(repository.lastCreatedTargetRoleIds, ['role-team-lead']);
    },
  );

  testWidgets(
    'pre-fills the form and saves an update when editing an existing article',
    (tester) async {
      await _useTallSurface(tester);
      final repository = FakeKnowledgeBaseRepository();
      final existing = buildTestKnowledgeBaseArticle(
        id: 'article-1',
        title: 'Old Title',
      );

      await tester.pumpWidget(
        _app(
          child: KnowledgeBaseEditorPage(existingArticle: existing),
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Article'), findsOneWidget);
      expect(find.text('Old Title'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'New Title');
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(repository.lastUpdatedId, 'article-1');
      expect(repository.lastUpdatedTitle, 'New Title');
    },
  );
}
