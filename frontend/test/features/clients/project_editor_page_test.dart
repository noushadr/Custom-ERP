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

  testWidgets('has no Package or Services fields', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Package'), findsNothing);
    expect(find.text('Services'), findsNothing);
  });

  testWidgets('departments come before the employee search, and employees '
      'are found by typing a name', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final departmentsY = tester.getTopLeft(find.text('Departments')).dy;
    final employeesY = tester.getTopLeft(find.text('Assigned employees')).dy;
    expect(departmentsY, lessThan(employeesY));

    // Employees aren't listed as chips up front — you search for them.
    expect(find.widgetWithText(FilterChip, 'Jane Doe'), findsNothing);

    final search = find.widgetWithText(TextField, 'Search employees by name');
    await tester.ensureVisible(search);
    await tester.enterText(search, 'jan');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Jane Doe'));
    await tester.pumpAndSettle();

    final chip = find.widgetWithText(InputChip, 'Jane Doe');
    expect(chip, findsOneWidget);
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(of: chip, matching: find.byTooltip('Delete')),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'Jane Doe'), findsNothing);
  });

  testWidgets('does not offer the Admin Staff department or its employees', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => PresetAuthController(AuthAuthenticated(_superAdmin)),
          ),
          employeeRepositoryProvider.overrideWithValue(
            FakeEmployeeRepository(
              employees: [
                buildTestEmployee(
                  id: 'e-eng',
                  fullName: 'Eve Doe',
                  department: const NamedRef(id: 'dept-1', name: 'Engineering'),
                ),
                buildTestEmployee(
                  id: 'e-admin',
                  fullName: 'Abu Doe',
                  department: const NamedRef(id: 'dept-9', name: 'Admin Staff'),
                ),
              ],
              departments: const [
                Department(id: 'dept-1', name: 'Engineering'),
                Department(id: 'dept-9', name: 'Admin Staff'),
              ],
            ),
          ),
          clientsRepositoryProvider.overrideWithValue(
            FakeClientsRepository(clients: [buildTestClient()]),
          ),
        ],
        child: const MaterialApp(home: ProjectEditorPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilterChip, 'Engineering'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Admin Staff'), findsNothing);

    final search = find.widgetWithText(TextField, 'Search employees by name');
    await tester.ensureVisible(search);
    await tester.enterText(search, 'e');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Eve Doe'), findsOneWidget);
    await tester.enterText(search, 'abu');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Abu Doe'), findsNothing);
  });

  testWidgets('the employee search only offers people still working here', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => PresetAuthController(AuthAuthenticated(_superAdmin)),
          ),
          employeeRepositoryProvider.overrideWithValue(
            FakeEmployeeRepository(
              employees: [
                buildTestEmployee(id: 'e1', fullName: 'Sam Active'),
                buildTestEmployee(
                  id: 'e2',
                  fullName: 'Sam Resigned',
                  employmentStatus: 'resigned',
                ),
                buildTestEmployee(
                  id: 'e3',
                  fullName: 'Sam Terminated',
                  employmentStatus: 'terminated',
                ),
              ],
            ),
          ),
          clientsRepositoryProvider.overrideWithValue(
            FakeClientsRepository(clients: [buildTestClient()]),
          ),
        ],
        child: const MaterialApp(home: ProjectEditorPage()),
      ),
    );
    await tester.pumpAndSettle();

    final search = find.widgetWithText(TextField, 'Search employees by name');
    await tester.ensureVisible(search);
    await tester.enterText(search, 'sam');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Sam Active'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Sam Resigned'), findsNothing);
    expect(find.widgetWithText(ListTile, 'Sam Terminated'), findsNothing);
  });

  testWidgets('shows a Deadline for a one-time project and a Renewal date '
      'for a monthly retainer — only the one that fits', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Deadline'), findsOneWidget);
    expect(find.text('Renewal date'), findsNothing);

    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<String>, 'Type'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retainer').last);
    await tester.pumpAndSettle();

    expect(find.text('Renewal date'), findsOneWidget);
    expect(find.text('Deadline'), findsNothing);
  });

  testWidgets('a one-time project needs a deadline before it can be created', (
    tester,
  ) async {
    final repository = FakeClientsRepository(clients: [buildTestClient()]);
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Project name'),
      'New Site',
    );
    final clientField = find.widgetWithText(TextFormField, 'Client');
    await tester.enterText(clientField, 'acme');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Acme Co'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('project-start-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create Project'));
    await tester.tap(find.text('Create Project'));
    await tester.pumpAndSettle();

    expect(find.text('Set a deadline.'), findsOneWidget);
    expect(repository.lastCreatedProjectName, isNull);

    await tester.tap(find.byKey(const Key('project-deadline')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create Project'));
    await tester.tap(find.text('Create Project'));
    await tester.pumpAndSettle();

    expect(repository.lastCreatedProjectName, 'New Site');
    expect(repository.lastCreatedEndDate, isNotNull);
    expect(repository.lastCreatedRenewalDate, isNull);
  });

  testWidgets('offers "+ Add" when the client search finds nothing, and the '
      'new client gets selected', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Client'),
      'Brand New Co',
    );
    await tester.pumpAndSettle();

    expect(find.text('Add "Brand New Co" as a new client'), findsOneWidget);
    await tester.tap(find.text('Add "Brand New Co" as a new client'));
    await tester.pumpAndSettle();

    // The quick-add dialog opens pre-filled with what was typed.
    expect(find.text('New client'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Brand New Co'), findsOneWidget);
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Back on the form with the new client chosen.
    expect(find.text('New client'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Brand New Co'), findsOneWidget);
  });

  testWidgets('the account manager is picked from the assigned employees', (
    tester,
  ) async {
    final repository = FakeClientsRepository(clients: [buildTestClient()]);
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    final owner = find.byKey(const Key('project-account-manager'));
    await tester.ensureVisible(owner);
    // Disabled until someone is assigned.
    expect(
      tester.widget<DropdownButtonFormField<String>>(owner).onChanged,
      isNull,
    );

    final search = find.widgetWithText(TextField, 'Search employees by name');
    await tester.ensureVisible(search);
    await tester.enterText(search, 'jan');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Jane Doe'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(owner);
    await tester.tap(owner);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jane Doe').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Project name'),
      'Owned Project',
    );
    final clientField = find.widgetWithText(TextFormField, 'Client');
    await tester.ensureVisible(clientField);
    await tester.enterText(clientField, 'acme');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Acme Co'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('project-start-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('project-deadline')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create Project'));
    await tester.tap(find.text('Create Project'));
    await tester.pumpAndSettle();

    expect(repository.lastCreatedAccountManagerId, isNotNull);
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
