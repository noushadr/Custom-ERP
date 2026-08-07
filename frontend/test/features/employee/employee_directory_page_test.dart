import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/presentation/pages/employee_directory_page.dart';
import 'package:zera_erp/shared/models/named_ref.dart';

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

  testWidgets('hierarchy view nests reports under their manager', (
    tester,
  ) async {
    final manager = buildTestEmployee(
      id: 'manager-1',
      fullName: 'Mona Manager',
      designation: 'Engineering Lead',
    );
    final report = buildTestEmployee(
      id: 'report-1',
      fullName: 'Ravi Report',
      designation: 'Software Engineer',
      reportingManager: const NamedRef(id: 'manager-1', name: 'Mona Manager'),
    );
    final repository = FakeEmployeeRepository(employees: [manager, report]);

    await tester.pumpWidget(
      _app(permissions: ['employees.read'], repository: repository),
    );
    await tester.pumpAndSettle();

    // Default view is the flat list.
    expect(find.text('Mona Manager'), findsOneWidget);
    expect(find.text('Ravi Report'), findsOneWidget);

    await tester.tap(find.text('Hierarchy'));
    await tester.pumpAndSettle();

    // Nodes start collapsed until the user opens them.
    expect(find.text('Mona Manager'), findsOneWidget);
    expect(find.text('Ravi Report'), findsNothing);
    expect(find.textContaining('1 person'), findsOneWidget);

    await tester.tap(find.textContaining('1 person'));
    await tester.pumpAndSettle();

    // The report is nested under the manager, not shown as a root.
    expect(find.text('Mona Manager'), findsOneWidget);
    expect(find.text('Ravi Report'), findsOneWidget);
  });

  testWidgets('filters the list by search query', (tester) async {
    final jane = buildTestEmployee(id: 'employee-1', fullName: 'Jane Doe');
    final ravi = buildTestEmployee(
      id: 'employee-2',
      fullName: 'Ravi Report',
      email: 'ravi.report@zeracreative.com',
      designation: 'Software Engineer',
    );
    final repository = FakeEmployeeRepository(employees: [jane, ravi]);

    await tester.pumpWidget(
      _app(permissions: ['employees.read'], repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Ravi Report'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ravi');
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsNothing);
    expect(find.text('Ravi Report'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nobody matches this');
    await tester.pumpAndSettle();

    expect(find.text('No employees match your search.'), findsOneWidget);
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
