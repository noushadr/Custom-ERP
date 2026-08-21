import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/clients/application/clients_providers.dart';
import 'package:zera_erp/features/clients/presentation/pages/project_editor_page.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/entities/department.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_clients.dart';
import '../../helpers/fake_employee.dart';

const _superAdmin = AuthUser(
  id: 'admin-1',
  email: 'admin@zeracreative.com',
  role: 'Super Admin',
  permissions: ['clients.manage'],
);

Widget _app({FakeClientsRepository? repository}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(_superAdmin)),
      ),
      employeeRepositoryProvider.overrideWithValue(
        FakeEmployeeRepository(
          employees: [buildTestEmployee()],
          departments: const [
            Department(id: 'dept-1', name: 'Engineering'),
          ],
        ),
      ),
      clientsRepositoryProvider.overrideWithValue(
        repository ??
            FakeClientsRepository(
              clients: [buildTestClient()],
              services: [buildTestService()],
            ),
      ),
    ],
    child: const MaterialApp(home: ProjectEditorPage()),
  );
}

void main() {
  testWidgets('shows a validation error when required fields are empty', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Project'));
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsWidgets);
  });

  testWidgets('the net-price preview updates live as price/deduction change', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Original client price (PKR)'),
      '1000',
    );
    await tester.pumpAndSettle();

    // Default deduction is 20%, so net price should be 800.00.
    expect(
      find.text('Net price: PKR 800.00 · Profit: PKR 800.00'),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Deduction %'),
      '50',
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Net price: PKR 500.00 · Profit: PKR 500.00'),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cost (PKR)'),
      '100',
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Net price: PKR 500.00 · Profit: PKR 400.00'),
      findsOneWidget,
    );
  });

  testWidgets('lets the admin toggle an employee, department, and service chip', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final employeeChip = find.widgetWithText(FilterChip, 'Jane Doe');
    final departmentChip = find.widgetWithText(FilterChip, 'Engineering');
    final serviceChip = find.widgetWithText(FilterChip, 'SEO');

    expect(employeeChip, findsOneWidget);
    expect(departmentChip, findsOneWidget);
    expect(serviceChip, findsOneWidget);

    FilterChip chipWidget(Finder finder) => tester.widget<FilterChip>(finder);
    expect(chipWidget(employeeChip).selected, isFalse);

    await tester.ensureVisible(employeeChip);
    await tester.tap(employeeChip);
    await tester.pumpAndSettle();

    expect(chipWidget(find.widgetWithText(FilterChip, 'Jane Doe')).selected, isTrue);
  });

  testWidgets('pre-fills fields when editing an existing project', (
    tester,
  ) async {
    final existing = buildTestProject(
      name: 'Existing Project',
      originalClientPrice: 2000,
      deductionRate: 10,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => PresetAuthController(AuthAuthenticated(_superAdmin)),
          ),
          employeeRepositoryProvider.overrideWithValue(
            FakeEmployeeRepository(),
          ),
          clientsRepositoryProvider.overrideWithValue(
            FakeClientsRepository(clients: [buildTestClient()]),
          ),
        ],
        child: MaterialApp(
          home: ProjectEditorPage(existingProject: existing),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Project'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
    final nameField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Project name'),
    );
    expect(nameField.controller?.text, 'Existing Project');
  });
}
