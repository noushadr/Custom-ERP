import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/presentation/pages/employee_profile_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';

Widget _app({
  required AuthUser viewer,
  required FakeEmployeeRepository repository,
  String? employeeId,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(viewer)),
      ),
      employeeRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(home: EmployeeProfilePage(employeeId: employeeId)),
  );
}

void main() {
  testWidgets('shows Edit for your own profile and opens the self-service form', (
    tester,
  ) async {
    final me = buildTestEmployee(email: 'jane.doe@zeracreative.com');
    final viewer = AuthUser(
      id: 'user-1',
      email: 'jane.doe@zeracreative.com',
      role: 'Employee',
      permissions: const [],
    );

    await tester.pumpWidget(
      _app(viewer: viewer, repository: FakeEmployeeRepository(me: me)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit My Profile'), findsOneWidget);
  });

  testWidgets(
    'shows Edit for someone else\'s profile when the viewer can manage employees',
    (tester) async {
      final other = buildTestEmployee(
        id: 'employee-2',
        email: 'other.person@zeracreative.com',
        fullName: 'Other Person',
      );
      final viewer = AuthUser(
        id: 'hr-1',
        email: 'hr.manager@zeracreative.com',
        role: 'HR/Manager',
        permissions: const ['employees.read', 'employees.manage'],
      );

      await tester.pumpWidget(
        _app(
          viewer: viewer,
          employeeId: 'employee-2',
          repository: FakeEmployeeRepository(employees: [other]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Other Person'), findsOneWidget);
    },
  );

  testWidgets(
    'hides Edit for someone else\'s profile when the viewer cannot manage employees',
    (tester) async {
      final other = buildTestEmployee(
        id: 'employee-2',
        email: 'other.person@zeracreative.com',
        fullName: 'Other Person',
      );
      final viewer = AuthUser(
        id: 'user-3',
        email: 'coworker@zeracreative.com',
        role: 'Employee',
        permissions: const ['employees.read'],
      );

      await tester.pumpWidget(
        _app(
          viewer: viewer,
          employeeId: 'employee-2',
          repository: FakeEmployeeRepository(employees: [other]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsNothing);
    },
  );
}
