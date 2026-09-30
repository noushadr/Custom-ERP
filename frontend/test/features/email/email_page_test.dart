import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/email/application/email_providers.dart';
import 'package:zera_erp/features/email/domain/entities/inbox_message.dart'
    show EmailThread, EmailThreadDetail, EmailThreadMessage;
import 'package:zera_erp/features/email/presentation/pages/email_page.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_email.dart';
import '../../helpers/fake_employee.dart';

Widget _app({
  String role = 'Employee',
  List<String> permissions = const [],
  FakeEmailRepository? emailRepository,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(
          AuthAuthenticated(
            AuthUser(
              id: 'user-1',
              email: 'jane.doe@zeracreative.com',
              role: role,
              permissions: permissions,
            ),
          ),
        ),
      ),
      emailRepositoryProvider.overrideWithValue(
        emailRepository ?? FakeEmailRepository(),
      ),
      employeeRepositoryProvider.overrideWithValue(FakeEmployeeRepository()),
    ],
    child: const MaterialApp(home: Scaffold(body: EmailPage())),
  );
}

void main() {
  testWidgets('shows the setup form when no mailbox is configured yet', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Set up your mailbox'), findsOneWidget);
    expect(find.text('Mailbox address'), findsOneWidget);
  });

  testWidgets('shows the inbox and compose action once a mailbox exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        emailRepository: FakeEmailRepository(
          myAccount: buildTestEmailAccount(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('employee@zeracreative.com'), findsOneWidget);
    expect(find.text('Compose'), findsOneWidget);
    expect(find.text('No conversations yet.'), findsOneWidget);
  });

  testWidgets('hides the admin mailbox manager without email.manage', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Manage a mailbox for another employee'), findsNothing);
  });

  testWidgets('shows the admin mailbox manager for an email.manage holder', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(role: 'HR/Manager', permissions: const ['email.manage']),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manage a mailbox for another employee'), findsOneWidget);
  });

  testWidgets(
    'switching to the Sent tab shows sent conversations, To-prefixed',
    (tester) async {
      await tester.pumpWidget(
        _app(
          emailRepository: FakeEmailRepository(
            myAccount: buildTestEmailAccount(),
            threads: [
              EmailThread(
                threadId: 't1',
                subject: 'Project update',
                participants: const ['A Client'],
                lastDate: DateTime(2026, 9, 1),
                messageCount: 1,
                hasUnread: false,
                hasInboxMessage: false,
                hasSentMessage: true,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No conversations yet.'), findsOneWidget);

      await tester.tap(find.text('Sent'));
      await tester.pumpAndSettle();

      expect(find.text('To: A Client'), findsOneWidget);
      expect(find.text('No conversations yet.'), findsNothing);
    },
  );

  testWidgets(
    'a conversation with no inbound messages hides the Reply button',
    (tester) async {
      await tester.pumpWidget(
        _app(
          emailRepository: FakeEmailRepository(
            myAccount: buildTestEmailAccount(),
            threads: [
              EmailThread(
                threadId: 't1',
                subject: 'Project update',
                participants: const ['client@example.com'],
                lastDate: DateTime(2026, 9, 1),
                messageCount: 1,
                hasUnread: false,
                hasInboxMessage: false,
                hasSentMessage: true,
              ),
            ],
            threadDetail: EmailThreadDetail(
              threadId: 't1',
              subject: 'Project update',
              messages: [
                EmailThreadMessage(
                  mailbox: 'sent',
                  uid: 1,
                  from: 'employee@zeracreative.com',
                  to: 'client@example.com',
                  date: DateTime(2026, 9, 1),
                  text: 'Body',
                  isUnread: false,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sent'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('To: client@example.com'));
      await tester.pumpAndSettle();

      expect(find.text('Reply'), findsNothing);
      expect(find.textContaining('To client@example.com'), findsOneWidget);
      expect(find.textContaining('Body'), findsOneWidget);
    },
  );
}
