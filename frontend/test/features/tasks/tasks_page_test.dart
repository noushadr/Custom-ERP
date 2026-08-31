import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/entities/department.dart';
import 'package:zera_erp/features/employee/presentation/widgets/employee_avatar.dart';
import 'package:zera_erp/features/tasks/application/task_providers.dart';
import 'package:zera_erp/features/tasks/domain/entities/task_status.dart';
import 'package:zera_erp/features/tasks/presentation/pages/tasks_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_task.dart';

Widget _app({
  AuthUser user = testAuthUser,
  List<Department> departments = const [],
  FakeTaskRepository? repository,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(user)),
      ),
      employeeRepositoryProvider.overrideWithValue(
        FakeEmployeeRepository(departments: departments),
      ),
      taskRepositoryProvider.overrideWithValue(
        repository ?? FakeTaskRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: TasksPage())),
  );
}

void main() {
  testWidgets('shows only the My Tasks tab for a plain employee', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('My Tasks'), findsOneWidget);
    expect(find.text('Assigned Tasks'), findsNothing);
    expect(find.text('Team Tasks'), findsNothing);
    expect(find.text('New Task'), findsNothing);
  });

  testWidgets('shows all three tabs for a tasks.manage holder', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        user: const AuthUser(
          id: 'admin-1',
          email: 'admin@zeracreative.com',
          role: 'Super Admin',
          permissions: ['tasks.manage'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Tasks'), findsOneWidget);
    expect(find.text('Assigned Tasks'), findsOneWidget);
    expect(find.text('Team Tasks'), findsOneWidget);
    expect(find.text('New Task'), findsOneWidget);
  });

  testWidgets(
    'shows all three tabs for a department head with no tasks.manage permission',
    (tester) async {
      await tester.pumpWidget(
        _app(
          departments: const [
            Department(
              id: 'dept-1',
              name: 'Engineering',
              headEmployeeId: 'employee-1',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Assigned Tasks'), findsOneWidget);
      expect(find.text('Team Tasks'), findsOneWidget);
    },
  );

  testWidgets('shows an empty-state message when there are no tasks', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('No tasks assigned to you yet.'), findsOneWidget);
  });

  testWidgets('shows an avatar for the assignee on each row', (tester) async {
    final repository = FakeTaskRepository(myTasks: [buildTestTask()]);

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.byType(EmployeeAvatar), findsOneWidget);
  });

  testWidgets('lists tasks sorted by due date ascending', (tester) async {
    final repository = FakeTaskRepository(
      myTasks: [
        buildTestTask(id: 'task-1', title: 'Later task', dueDate: '2026-12-20'),
        buildTestTask(
          id: 'task-2',
          title: 'Sooner task',
          dueDate: '2026-12-01',
        ),
      ],
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    final sooner = find.text('Sooner task');
    final later = find.text('Later task');
    expect(sooner, findsOneWidget);
    expect(later, findsOneWidget);
    expect(
      tester.getTopLeft(sooner).dy,
      lessThan(tester.getTopLeft(later).dy),
    );
  });

  testWidgets('shows priority and status badges on each row', (tester) async {
    final repository = FakeTaskRepository(
      myTasks: [buildTestTask(status: TaskStatus.inProgress)],
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
  });

  testWidgets('shows who assigned each task', (tester) async {
    final repository = FakeTaskRepository(
      myTasks: [buildTestTask(assignedByName: 'Nauman Meghani')],
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.textContaining('Assigned by Nauman Meghani'), findsOneWidget);
  });

  testWidgets(
    'changing status from the row calls the repository directly, without '
    "opening the task's detail page",
    (tester) async {
      final repository = FakeTaskRepository(
        myTasks: [buildTestTask(status: TaskStatus.todo)],
      );

      await tester.pumpWidget(_app(repository: repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('To Do'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('In Progress').last);
      await tester.pumpAndSettle();

      expect(repository.lastStatusUpdatedId, 'task-1');
      expect(repository.lastStatusUpdatedStatus, TaskStatus.inProgress);
      // Still on the list — no task detail AppBar ("Task") was pushed.
      expect(find.text('Task'), findsNothing);
    },
  );
}
