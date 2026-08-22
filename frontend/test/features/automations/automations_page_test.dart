import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/automations/application/automations_providers.dart';
import 'package:zera_erp/features/automations/domain/entities/automation_type.dart';
import 'package:zera_erp/features/automations/presentation/pages/automations_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_automations.dart';

const _superAdmin = AuthUser(
  id: 'admin-1',
  email: 'admin@zeracreative.com',
  role: 'Super Admin',
  permissions: ['automations.manage'],
);

Widget _app({FakeAutomationsRepository? repository}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(_superAdmin)),
      ),
      automationsRepositoryProvider.overrideWithValue(
        repository ?? FakeAutomationsRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: AutomationsPage())),
  );
}

void main() {
  testWidgets('renders all 3 automations with their labels and descriptions', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Project Renewal Reminder'), findsOneWidget);
    expect(find.text('Task Deadline Reminder'), findsOneWidget);
    expect(find.text('Annual Leave Reset'), findsOneWidget);
    expect(
      find.textContaining('everyone who manages Clients & Projects'),
      findsOneWidget,
    );
  });

  testWidgets('shows a Days before field only for the two reminder types', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Days before'), findsNWidgets(2));
  });

  testWidgets('toggling the switch updates isActive', (tester) async {
    final repository = FakeAutomationsRepository();
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(repository.lastUpdatedType, AutomationType.projectRenewalReminder);
    expect(repository.lastUpdatedIsActive, true);
  });

  testWidgets('editing and saving daysBefore updates that automation', (
    tester,
  ) async {
    final repository = FakeAutomationsRepository();
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    final field = find.widgetWithText(TextField, 'Days before').first;
    await tester.enterText(field, '10');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Save').first);
    await tester.pumpAndSettle();

    expect(repository.lastUpdatedType, AutomationType.projectRenewalReminder);
    expect(repository.lastUpdatedDaysBefore, 10);
  });

  testWidgets('shows a validation error for an invalid daysBefore value', (
    tester,
  ) async {
    final repository = FakeAutomationsRepository();
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    final field = find.widgetWithText(TextField, 'Days before').first;
    await tester.enterText(field, '0');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Save').first);
    await tester.pumpAndSettle();

    expect(repository.lastUpdatedType, isNull);
    expect(
      find.text('Enter a whole number of days, at least 1.'),
      findsOneWidget,
    );
  });

  testWidgets('tapping Run Now runs the automation and expands history', (
    tester,
  ) async {
    final repository = FakeAutomationsRepository(
      history: [
        buildTestAutomationExecutionHistoryEntry(
          type: AutomationType.projectRenewalReminder,
          itemsProcessed: 2,
          notificationsCreated: 3,
        ),
      ],
    );
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Run Now').first);
    await tester.pumpAndSettle();

    expect(repository.lastRunType, AutomationType.projectRenewalReminder);
    expect(
      find.textContaining('2 item(s) processed, 3 notification(s) sent'),
      findsOneWidget,
    );
  });

  testWidgets('shows an error run in history with its error message', (
    tester,
  ) async {
    final repository = FakeAutomationsRepository(
      history: [
        buildTestAutomationExecutionHistoryEntry(
          type: AutomationType.taskDeadlineReminder,
          status: 'error',
          errorMessage: 'DB unavailable',
        ),
      ],
    );
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    // Expand the second card's history (Task Deadline Reminder).
    final expansionTiles = find.text('Run history');
    await tester.tap(expansionTiles.at(1));
    await tester.pumpAndSettle();

    expect(find.text('DB unavailable'), findsOneWidget);
  });

  testWidgets('shows an empty state when a type has no run history', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Run history').first);
    await tester.pumpAndSettle();

    expect(find.text('No runs yet.'), findsOneWidget);
  });

  testWidgets('shows who last changed an automation once it has been updated', (
    tester,
  ) async {
    final repository = FakeAutomationsRepository(
      automations: [
        buildTestAutomation(
          type: AutomationType.projectRenewalReminder,
          updatedByName: 'Jane Admin',
        ),
      ],
    );
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.textContaining('Last changed by Jane Admin'), findsOneWidget);
  });
}
