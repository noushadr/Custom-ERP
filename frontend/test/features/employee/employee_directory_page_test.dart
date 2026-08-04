import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/presentation/pages/employee_directory_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';

Widget _app({
  required List<String> permissions,
  required FakeEmployeeRepository repository,
}) {
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
      employeeRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(home: Scaffold(body: EmployeeDirectoryPage())),
  );
}

void main() {
  testWidgets('shows the employee list and invite button with full access', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(
      employees: [buildTestEmployee()],
    );

    await tester.pumpWidget(
      _app(
        permissions: ['employees.read', 'employees.manage'],
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Invite Employee'), findsOneWidget);
  });

  testWidgets('hides the invite button without employees.manage', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(
      employees: [buildTestEmployee()],
    );

    await tester.pumpWidget(
      _app(permissions: ['employees.read'], repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Invite Employee'), findsNothing);
  });

  testWidgets('shows a restricted message without employees.read', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(
      employees: [buildTestEmployee()],
    );

    await tester.pumpWidget(_app(permissions: [], repository: repository));
    await tester.pumpAndSettle();

    expect(
      find.text("You don't have access to the full directory."),
      findsOneWidget,
    );
    expect(find.text('View my profile'), findsOneWidget);
  });
}
