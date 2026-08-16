import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/entities/department.dart';
import 'package:zera_erp/features/employee/domain/exceptions/employee_exception.dart';
import 'package:zera_erp/features/employee/presentation/pages/departments_page.dart';
import 'package:zera_erp/shared/models/named_ref.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';

Widget _app(FakeEmployeeRepository repository) {
  final user = AuthUser(
    id: 'user-1',
    email: 'jane.doe@zeracreative.com',
    role: 'HR/Manager',
    permissions: const ['departments.manage'],
  );

  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(user)),
      ),
      employeeRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(home: DepartmentsPage()),
  );
}

void main() {
  testWidgets('shows the list of departments with their head employee', (
    tester,
  ) async {
    final headEmployee = buildTestEmployee(
      id: 'employee-1',
      fullName: 'Mona Manager',
    );
    final repository = FakeEmployeeRepository(
      employees: [headEmployee],
      departments: const [
        Department(
          id: 'department-1',
          name: 'Engineering',
          description: 'Builds the product',
          headEmployeeId: 'employee-1',
        ),
        Department(id: 'department-2', name: 'Human Resources'),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Engineering'), findsOneWidget);
    expect(find.text('Builds the product'), findsOneWidget);
    expect(find.text('Head: Mona Manager'), findsOneWidget);
    expect(find.text('Human Resources'), findsOneWidget);
    expect(find.text('No department head assigned'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no departments', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository();

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No active departments. Turn on "Show archived" to see archived ones.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('adding a department calls createDepartment and refreshes', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(
      departments: const [
        Department(id: 'department-1', name: 'Engineering'),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Marketing');
    await tester.tap(find.text('Add department').last);
    await tester.pumpAndSettle();

    expect(repository.lastCreateDepartmentInput?.name, 'Marketing');
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('editing a department pre-fills the form and saves changes', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(
      departments: const [
        Department(
          id: 'department-1',
          name: 'Engineering',
          description: 'Builds the product',
        ),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Edit department'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Engineering'),
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(TextFormField).first,
      'Engineering & Platform',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(repository.lastUpdateDepartmentInput?.id, 'department-1');
    expect(
      repository.lastUpdateDepartmentInput?.name,
      'Engineering & Platform',
    );
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('shows the error message when creating a department fails', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(
      createDepartmentError: const EmployeeException('Name already exists.'),
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Engineering');
    await tester.tap(find.text('Add department').last);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('shows the number of employees assigned to each department', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(
      employees: [
        buildTestEmployee(
          id: 'employee-1',
          fullName: 'Ravi Report',
          department: const NamedRef(id: 'department-1', name: 'Engineering'),
        ),
        buildTestEmployee(
          id: 'employee-2',
          fullName: 'Amna Irfan',
          email: 'amna.irfan@zeracreative.com',
          department: const NamedRef(id: 'department-1', name: 'Engineering'),
        ),
      ],
      departments: const [
        Department(id: 'department-1', name: 'Engineering'),
        Department(id: 'department-2', name: 'Human Resources'),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('2 employees'), findsOneWidget);
    expect(find.text('0 employees'), findsOneWidget);
  });

  testWidgets('archiving a department calls setDepartmentArchived', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(
      departments: const [
        Department(id: 'department-1', name: 'Engineering'),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(repository.lastSetDepartmentArchivedInput?.id, 'department-1');
    expect(repository.lastSetDepartmentArchivedInput?.isArchived, true);
  });

  testWidgets(
    'shows an Archived badge and Unarchive option once "Show archived" is on',
    (tester) async {
      final repository = FakeEmployeeRepository(
        departments: const [
          Department(
            id: 'department-1',
            name: 'Engineering',
            isArchived: true,
          ),
        ],
      );

      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      // Hidden by default — the management screen excludes archived
      // departments until the viewer explicitly asks to see them.
      expect(find.text('Engineering'), findsNothing);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Engineering'), findsOneWidget);
      expect(find.text('Archived'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Unarchive'), findsOneWidget);
    },
  );

  testWidgets('deleting a department asks for confirmation before calling '
      'deleteDepartment', (tester) async {
    final repository = FakeEmployeeRepository(
      departments: const [
        Department(id: 'department-1', name: 'Engineering'),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete department?'), findsOneWidget);
    expect(repository.lastDeleteDepartmentId, isNull);

    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(repository.lastDeleteDepartmentId, 'department-1');
  });

  testWidgets('canceling the delete confirmation does not delete anything', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(
      departments: const [
        Department(id: 'department-1', name: 'Engineering'),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.lastDeleteDepartmentId, isNull);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    'shows the conflict message when a department still has employees assigned',
    (tester) async {
      final repository = FakeEmployeeRepository(
        departments: const [
          Department(id: 'department-1', name: 'Engineering'),
        ],
        deleteDepartmentError: const EmployeeException(
          'Cannot delete a department that still has employees '
          'assigned. Archive it instead.',
        ),
      );

      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Cannot delete a department that still has employees '
          'assigned. Archive it instead.',
        ),
        findsOneWidget,
      );
    },
  );
}
