import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/authentication/presentation/widgets/user_menu.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/presentation/pages/edit_my_profile_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';

Widget _app({required bool withLinkedEmployee}) {
  final user = AuthUser(
    id: 'user-1',
    email: 'jane.doe@zeracreative.com',
    role: 'Employee',
    permissions: const [],
  );

  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(user)),
      ),
      employeeRepositoryProvider.overrideWithValue(
        FakeEmployeeRepository(
          me: withLinkedEmployee ? buildTestEmployee() : null,
          getMeError: withLinkedEmployee ? null : Exception('no profile'),
        ),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: UserMenu(onSignOut: () {}),
      ),
    ),
  );
}

void main() {
  testWidgets('shows an Edit profile item that opens EditMyProfilePage', (
    tester,
  ) async {
    await tester.pumpWidget(_app(withLinkedEmployee: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Account menu'));
    await tester.pumpAndSettle();

    expect(find.text('Edit profile'), findsOneWidget);

    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();

    expect(find.byType(EditMyProfilePage), findsOneWidget);
  });

  testWidgets('disables Edit profile when there is no linked employee', (
    tester,
  ) async {
    await tester.pumpWidget(_app(withLinkedEmployee: false));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Account menu'));
    await tester.pumpAndSettle();

    expect(find.text('Edit profile'), findsOneWidget);

    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();

    // A disabled PopupMenuItem neither closes the menu nor navigates —
    // confirmed by the menu still being open and no EditMyProfilePage pushed.
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.byType(EditMyProfilePage), findsNothing);
  });

  testWidgets('Sign out still works', (tester) async {
    var signedOut = false;
    final user = AuthUser(
      id: 'user-1',
      email: 'jane.doe@zeracreative.com',
      role: 'Employee',
      permissions: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => PresetAuthController(AuthAuthenticated(user)),
          ),
          employeeRepositoryProvider.overrideWithValue(
            FakeEmployeeRepository(me: buildTestEmployee()),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: UserMenu(onSignOut: () => signedOut = true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Account menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(signedOut, isTrue);
  });
}
