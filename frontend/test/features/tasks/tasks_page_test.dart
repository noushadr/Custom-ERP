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
  testWidgets(
    'shows My Tasks/Available to Claim/Assigned Tasks but not Task Board for a plain employee',
    (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('My Tasks'), findsOneWidget);
      expect(find.text('Available to Claim'), findsOneWidget);
      expect(find.text('Assigned Tasks'), findsOneWidget);
      expect(find.text('Task Board'), findsNothing);
      // Anyone can create a task now — at minimum, assign it to a team.
      expect(find.text('New Task'), findsOneWidget);
    },
  );

  testWidgets('shows all four tabs for a tasks.manage holder', (tester) async {
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
    expect(find.text('Available to Claim'), findsOneWidget);
    expect(find.text('Assigned Tasks'), findsOneWidget);
    expect(find.text('Task Board'), findsOneWidget);
    expect(find.text('New Task'), findsOneWidget);
  });

  testWidgets(
    'shows the Task Board tab for a department head with no tasks.manage permission',
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
      expect(find.text('Task Board'), findsOneWidget);
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
    expect(tester.getTopLeft(sooner).dy, lessThan(tester.getTopLeft(later).dy));
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

      expect(repository.lastProgressUpdatedId, 'task-1');
      expect(repository.lastProgressUpdatedStatus, TaskStatus.inProgress);
      // Still on the list — no task detail AppBar ("Task") was pushed.
      expect(find.text('Task'), findsNothing);
    },
  );

  testWidgets(
    'changing priority from the row calls the repository directly, without '
    "opening the task's detail page",
    (tester) async {
      final repository = FakeTaskRepository(
        myTasks: [buildTestTask(priority: 'medium')],
      );

      await tester.pumpWidget(_app(repository: repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Medium'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('High').last);
      await tester.pumpAndSettle();

      expect(repository.lastUpdatedId, 'task-1');
      expect(repository.lastUpdatedPriority, 'high');
      expect(find.text('Task'), findsNothing);
    },
  );

  testWidgets(
    'changing the due date from the row calls the repository directly, '
    "without opening the task's detail page",
    (tester) async {
      final repository = FakeTaskRepository(
        myTasks: [buildTestTask(dueDate: '2026-09-18')],
      );

      await tester.pumpWidget(_app(repository: repository));
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('30').last);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(repository.lastProgressUpdatedId, 'task-1');
      expect(repository.lastProgressUpdatedDueDate, '2026-09-30');
      expect(find.text('Task'), findsNothing);

      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'an unclaimed team task shows a Claim button instead of a status menu, '
    'and claiming it calls the repository directly',
    (tester) async {
      final repository = FakeTaskRepository(
        claimableTasks: [
          buildTestTask(
            assigneeEmployeeId: null,
            assigneeName: null,
            departmentName: 'Engineering',
          ),
        ],
      );

      await tester.pumpWidget(_app(repository: repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Available to Claim'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Unclaimed'), findsOneWidget);
      expect(find.text('Claim'), findsOneWidget);

      await tester.tap(find.text('Claim'));
      await tester.pumpAndSettle();

      expect(repository.lastClaimedId, 'task-1');
    },
  );
}
