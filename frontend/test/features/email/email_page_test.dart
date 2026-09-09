import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/email/application/email_providers.dart';
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
    expect(find.text('No messages yet.'), findsOneWidget);
  });

  testWidgets('hides the admin mailbox manager without email.manage', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(
      find.text('Manage a mailbox for another employee'),
      findsNothing,
    );
  });

  testWidgets('shows the admin mailbox manager for an email.manage holder', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(role: 'HR/Manager', permissions: const ['email.manage']),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Manage a mailbox for another employee'),
      findsOneWidget,
    );
  });
}
