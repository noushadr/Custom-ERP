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
import 'package:zera_erp/shared/models/named_ref.dart';

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
          employees: [
            buildTestEmployee(
              department: const NamedRef(id: 'dept-1', name: 'Engineering'),
            ),
          ],
          departments: const [
            Department(id: 'dept-1', name: 'Engineering'),
            Department(id: 'dept-2', name: 'Marketing'),
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

  testWidgets('lets the admin toggle an employee and service chip', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final employeeChip = find.widgetWithText(FilterChip, 'Jane Doe');
    final serviceChip = find.widgetWithText(FilterChip, 'SEO');

    expect(employeeChip, findsOneWidget);
    expect(serviceChip, findsOneWidget);

    FilterChip chipWidget(Finder finder) => tester.widget<FilterChip>(finder);
    expect(chipWidget(employeeChip).selected, isFalse);

    await tester.ensureVisible(employeeChip);
    await tester.tap(employeeChip);
    await tester.pumpAndSettle();

    expect(
      chipWidget(find.widgetWithText(FilterChip, 'Jane Doe')).selected,
      isTrue,
    );
  });

  testWidgets(
    'lets the admin pick departments directly, showing a Hybrid badge once '
    'more than one is selected',
    (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Hybrid'), findsNothing);

      final engineeringChip = find.widgetWithText(FilterChip, 'Engineering');
      final marketingChip = find.widgetWithText(FilterChip, 'Marketing');
      expect(engineeringChip, findsOneWidget);
      expect(marketingChip, findsOneWidget);

      await tester.ensureVisible(engineeringChip);
      await tester.tap(engineeringChip);
      await tester.pumpAndSettle();

      expect(find.text('Hybrid'), findsNothing);

      await tester.ensureVisible(marketingChip);
      await tester.tap(marketingChip);
      await tester.pumpAndSettle();

      expect(find.text('Hybrid'), findsOneWidget);

      await tester.tap(marketingChip);
      await tester.pumpAndSettle();

      expect(find.text('Hybrid'), findsNothing);
    },
  );

  testWidgets('pre-fills fields when editing an existing project', (
    tester,
  ) async {
    final existing = buildTestProject(name: 'Existing Project');

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
        child: MaterialApp(home: ProjectEditorPage(existingProject: existing)),
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
