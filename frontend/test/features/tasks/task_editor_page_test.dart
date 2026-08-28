import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/entities/department.dart';
import 'package:zera_erp/features/employee/domain/entities/employee.dart';
import 'package:zera_erp/features/tasks/application/task_providers.dart';
import 'package:zera_erp/features/tasks/domain/entities/task_priority.dart';
import 'package:zera_erp/features/tasks/presentation/pages/task_editor_page.dart';
import 'package:zera_erp/shared/models/named_ref.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_task.dart';

Widget _app({
  AuthUser user = testAuthUser,
  List<Employee> employees = const [],
  List<Department> departments = const [],
  FakeTaskRepository? repository,
  Widget? child,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(user)),
      ),
      employeeRepositoryProvider.overrideWithValue(
        FakeEmployeeRepository(employees: employees, departments: departments),
      ),
      taskRepositoryProvider.overrideWithValue(
        repository ?? FakeTaskRepository(),
      ),
    ],
    child: MaterialApp(home: child ?? const TaskEditorPage()),
  );
}

void main() {
  testWidgets('shows validation errors for an empty form', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Create Task'));
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsWidgets);
  });

  testWidgets(
    'restricts the assignee dropdown to a department head\'s own department',
    (tester) async {
      await tester.pumpWidget(
        _app(
          employees: [
            buildTestEmployee(
              id: 'employee-2',
              fullName: 'In Department',
              department: const NamedRef(id: 'dept-1', name: 'Engineering'),
            ),
            buildTestEmployee(
              id: 'employee-3',
              fullName: 'Outside Department',
              department: const NamedRef(id: 'dept-2', name: 'Sales'),
            ),
          ],
          departments: const [
            Department(
              id: 'dept-1',
              name: 'Engineering',
              headEmployeeId: 'employee-1',
            ),
            Department(id: 'dept-2', name: 'Sales', headEmployeeId: 'other'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Assignee'));
      await tester.pumpAndSettle();

      expect(find.text('In Department'), findsOneWidget);
      expect(find.text('Outside Department'), findsNothing);
    },
  );

  testWidgets('submits the entered values on create', (tester) async {
    final repository = FakeTaskRepository();

    await tester.pumpWidget(
      _app(
        user: const AuthUser(
          id: 'admin-1',
          email: 'admin@zeracreative.com',
          role: 'Super Admin',
          permissions: ['tasks.manage'],
        ),
        employees: [
          buildTestEmployee(id: 'employee-2', fullName: 'Target Person'),
        ],
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Ship the release',
    );

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Assignee'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Target Person').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('task-due-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Create Task'));
    await tester.pumpAndSettle();

    expect(repository.lastCreatedTitle, 'Ship the release');
    expect(repository.lastCreatedAssigneeEmployeeId, 'employee-2');
    expect(repository.lastCreatedPriority, TaskPriority.medium);
  });

  testWidgets('pre-fills fields when editing an existing task', (
    tester,
  ) async {
    final existing = buildTestTask(
      title: 'Existing task',
      priority: TaskPriority.high,
    );

    await tester.pumpWidget(
      _app(
        user: const AuthUser(
          id: 'admin-1',
          email: 'admin@zeracreative.com',
          role: 'Super Admin',
          permissions: ['tasks.manage'],
        ),
        employees: [buildTestEmployee(id: 'employee-1', fullName: 'Jane Doe')],
        child: TaskEditorPage(existingTask: existing),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Task'), findsOneWidget);
    expect(find.text('Existing task'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
  });
}
