import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/settings/presentation/pages/settings_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';

Widget _app({required List<String> permissions}) {
  final user = AuthUser(
    id: 'user-1',
    email: 'jane.doe@zeracreative.com',
    role: 'HR/Manager',
    permissions: permissions,
  );

  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(user)),
      ),
      employeeRepositoryProvider.overrideWithValue(FakeEmployeeRepository()),
    ],
    child: const MaterialApp(home: SettingsPage()),
  );
}

void main() {
  testWidgets('shows every entry for a viewer with every permission', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        permissions: const [
          'departments.manage',
          'leave.manage',
          'roles.manage',
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Departments'), findsOneWidget);
    expect(find.text('Leave Types & Policies'), findsOneWidget);
    expect(find.text('Public Holidays'), findsOneWidget);
    expect(find.text('Roles & Permissions'), findsOneWidget);
  });

  testWidgets('hides every entry for a viewer with no admin permissions', (
    tester,
  ) async {
    await tester.pumpWidget(_app(permissions: const []));
    await tester.pumpAndSettle();

    expect(find.text('Departments'), findsNothing);
    expect(find.text('Leave Types & Policies'), findsNothing);
    expect(find.text('Public Holidays'), findsNothing);
    expect(find.text('Roles & Permissions'), findsNothing);
    expect(find.text("You don't have access to any settings."), findsOneWidget);
  });

  testWidgets('tapping Departments navigates to the departments page', (
    tester,
  ) async {
    await tester.pumpWidget(_app(permissions: const ['departments.manage']));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Departments'));
    await tester.pumpAndSettle();

    expect(find.text('Manage Departments'), findsOneWidget);
  });
}
