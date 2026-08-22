import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/checklists/application/checklist_providers.dart';
import 'package:zera_erp/features/checklists/domain/exceptions/checklist_exception.dart';
import 'package:zera_erp/features/checklists/presentation/pages/checklist_templates_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_checklist.dart';

Future<void> _useTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app({FakeChecklistRepository? checklistRepository}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(const AuthAuthenticated(testAuthUser)),
      ),
      checklistRepositoryProvider.overrideWithValue(
        checklistRepository ?? FakeChecklistRepository(),
      ),
    ],
    child: const MaterialApp(home: ChecklistTemplatesPage()),
  );
}

void main() {
  testWidgets('lists existing onboarding checklist items', (tester) async {
    await _useTallSurface(tester);
    await tester.pumpWidget(
      _app(
        checklistRepository: FakeChecklistRepository(
          templateItems: [
            buildTestChecklistTemplateItem(
              id: 'template-1',
              title: 'Acceptance of offer letter via email',
            ),
            buildTestChecklistTemplateItem(
              id: 'template-2',
              title: 'Review office rules and regulations',
              appliesToWorkMode: 'on_site',
              sortOrder: 1,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acceptance of offer letter via email'), findsOneWidget);
    expect(find.text('Review office rules and regulations'), findsOneWidget);
    expect(find.text('On-site only'), findsOneWidget);
  });

  testWidgets('adding a checklist item calls createTemplateItem', (
    tester,
  ) async {
    await _useTallSurface(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Add to company communication groups',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add item'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('archiving an item calls setTemplateItemArchived', (
    tester,
  ) async {
    await _useTallSurface(tester);
    await tester.pumpWidget(
      _app(
        checklistRepository: FakeChecklistRepository(
          templateItems: [buildTestChecklistTemplateItem(id: 'template-1')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('moving an item down reorders with the recomputed id list', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = FakeChecklistRepository(
      templateItems: [
        buildTestChecklistTemplateItem(id: 'a', title: 'First', sortOrder: 0),
        buildTestChecklistTemplateItem(id: 'b', title: 'Second', sortOrder: 1),
      ],
    );
    await tester.pumpWidget(_app(checklistRepository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Move down').first);
    await tester.pumpAndSettle();

    expect(repository.lastReorderedIds, ['b', 'a']);
  });

  testWidgets(
    'deleting an item that already has employee checklists shows the conflict message',
    (tester) async {
      await _useTallSurface(tester);
      await tester.pumpWidget(
        _app(
          checklistRepository: FakeChecklistRepository(
            templateItems: [
              buildTestChecklistTemplateItem(id: 'template-1'),
            ],
            deleteTemplateItemError: const ChecklistException(
              'Cannot delete a checklist item that already has employee '
              'checklists created against it. Archive it instead.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('already has employee checklists'),
        findsOneWidget,
      );
    },
  );
}
