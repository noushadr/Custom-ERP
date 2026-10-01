import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/notifications/application/notifications_providers.dart';
import 'package:zera_erp/features/notifications/domain/entities/notification_mute_preference.dart';
import 'package:zera_erp/features/notifications/presentation/widgets/notification_preferences_dialog.dart';

import '../../helpers/fake_notifications.dart';

Future<void> _pumpDialog(
  WidgetTester tester, {
  required FakeNotificationsRepository repository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [notificationsRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const NotificationPreferencesDialog(),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists every known category with its current muted state', (
    tester,
  ) async {
    final repository = FakeNotificationsRepository(
      mutePreferences: const [
        NotificationMutePreference(
          category: 'task_deadline_reminder',
          label: 'Task deadline reminders (on tasks assigned to you)',
          muted: true,
        ),
        NotificationMutePreference(
          category: 'leave_applied_for_you',
          label: 'Leave applied on your behalf',
          muted: false,
        ),
      ],
    );

    await _pumpDialog(tester, repository: repository);

    expect(
      find.text('Task deadline reminders (on tasks assigned to you)'),
      findsOneWidget,
    );
    expect(find.text('Leave applied on your behalf'), findsOneWidget);

    final switches = tester.widgetList<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    final deadlineSwitch = switches.firstWhere(
      (s) =>
          (s.title as Text).data ==
          'Task deadline reminders (on tasks assigned to you)',
    );
    final leaveSwitch = switches.firstWhere(
      (s) => (s.title as Text).data == 'Leave applied on your behalf',
    );
    expect(deadlineSwitch.value, isFalse);
    expect(leaveSwitch.value, isTrue);
  });

  testWidgets('toggling a switch off mutes that category', (tester) async {
    final repository = FakeNotificationsRepository(
      mutePreferences: const [
        NotificationMutePreference(
          category: 'payroll_paid',
          label: 'Payroll paid',
          muted: false,
        ),
      ],
    );

    await _pumpDialog(tester, repository: repository);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(repository.lastSetMuteCategory, 'payroll_paid');
    expect(repository.lastSetMuteValue, isTrue);
  });
}
