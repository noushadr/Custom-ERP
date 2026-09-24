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
    'shows My Tasks/Available to Claim/Assigned Tasks but not Team Task '
    'Board for a plain employee',
    (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('My Tasks'), findsOneWidget);
      expect(find.text('Available to Claim'), findsOneWidget);
      expect(find.text('Assigned Tasks'), findsOneWidget);
      expect(find.text('Team Task Board'), findsNothing);
      // Anyone can create a task now — at minimum, assign it to a team.
      expect(find.text('New Task'), findsOneWidget);
    },
  );

  testWidgets(
    'badges the Available to Claim tab with the unclaimed count, as its own '
    "widget after the label — not overlapping the word 'Claim'",
    (tester) async {
      final repository = FakeTaskRepository(
        claimableTasks: [
          buildTestTask(assigneeEmployeeId: null, assigneeName: null),
        ],
      );

      await tester.pumpWidget(_app(repository: repository));
      await tester.pumpAndSettle();

      // The label renders whole and intact...
      final labelFinder = find.text('Available to Claim');
      expect(labelFinder, findsOneWidget);
      // ...with the badge a separate widget positioned to its right.
      final badgeFinder = find.text('1');
      expect(badgeFinder, findsOneWidget);
      expect(
        tester.getTopLeft(badgeFinder).dx,
        greaterThan(tester.getTopRight(labelFinder).dx),
      );
    },
  );

  testWidgets('shows no badge on the Available to Claim tab when nothing is '
      'unclaimed', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Available to Claim'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

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
    expect(find.text('Team Task Board'), findsOneWidget);
    expect(find.text('New Task'), findsOneWidget);
  });

  testWidgets(
    'shows the Team Task Board tab for a department head with no tasks.manage permission',
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
      expect(find.text('Team Task Board'), findsOneWidget);
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

  testWidgets('shows the priority tag on each card', (tester) async {
    final repository = FakeTaskRepository(
      myTasks: [buildTestTask(priority: 'medium')],
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Medium'), findsOneWidget);
  });

  testWidgets('shows who assigned each task, by name only', (tester) async {
    final repository = FakeTaskRepository(
      myTasks: [buildTestTask(assignedByName: 'Nauman Meghani')],
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('by Nauman Meghani'), findsOneWidget);
  });

  testWidgets('shows only To Do/In Progress/Completed columns — no Pending or '
      'Cancelled column', (tester) async {
    final repository = FakeTaskRepository(myTasks: [buildTestTask()]);

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('To Do'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Pending'), findsNothing);
    expect(find.text('Cancelled'), findsNothing);
  });

  testWidgets('shows days left until the due date on the card', (tester) async {
    final now = DateTime.now();
    final inThreeDays = now.add(const Duration(days: 3));
    final dueDate =
        '${inThreeDays.year.toString().padLeft(4, '0')}-'
        '${inThreeDays.month.toString().padLeft(2, '0')}-'
        '${inThreeDays.day.toString().padLeft(2, '0')}';
    final repository = FakeTaskRepository(
      myTasks: [buildTestTask(dueDate: dueDate)],
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.textContaining('3d left'), findsOneWidget);
  });

  testWidgets('shows how many comments a task has', (tester) async {
    final repository = FakeTaskRepository(
      myTasks: [buildTestTask(commentCount: 3)],
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
  });

  testWidgets(
    'the board groups each task into the column matching its status',
    (tester) async {
      final repository = FakeTaskRepository(
        myTasks: [
          buildTestTask(
            id: 'task-1',
            title: 'A todo task',
            status: TaskStatus.todo,
          ),
          buildTestTask(
            id: 'task-2',
            title: 'An in-progress task',
            status: TaskStatus.inProgress,
          ),
          buildTestTask(
            id: 'task-3',
            title: 'A completed task',
            status: TaskStatus.completed,
          ),
        ],
      );

      await tester.pumpWidget(_app(repository: repository));
      await tester.pumpAndSettle();

      final todoCard = tester.getTopLeft(find.text('A todo task'));
      final inProgressCard = tester.getTopLeft(
        find.text('An in-progress task'),
      );
      final completedCard = tester.getTopLeft(find.text('A completed task'));

      // Each column is a fixed ~280px width — a card in a later-status
      // column sits well to the right of one in an earlier column. The
      // column, not the card itself, is what tells you the status now.
      expect(inProgressCard.dx, greaterThan(todoCard.dx + 200));
      expect(completedCard.dx, greaterThan(inProgressCard.dx + 200));
    },
  );

  testWidgets(
    'dragging a card onto a different column moves it there, like Trello',
    (tester) async {
      final repository = FakeTaskRepository(
        myTasks: [
          buildTestTask(status: TaskStatus.todo, title: 'Draggable task'),
        ],
      );

      await tester.pumpWidget(_app(repository: repository));
      await tester.pumpAndSettle();

      final cardCenter = tester.getCenter(find.text('Draggable task'));
      final inProgressColumnCenter = tester.getCenter(find.text('In Progress'));

      final gesture = await tester.startGesture(cardCenter);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(inProgressColumnCenter);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(repository.lastProgressUpdatedId, 'task-1');
      expect(repository.lastProgressUpdatedStatus, TaskStatus.inProgress);
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

  testWidgets(
    "an unclaimed task's priority and due date chips aren't editable",
    (tester) async {
      final repository = FakeTaskRepository(
        claimableTasks: [
          buildTestTask(
            assigneeEmployeeId: null,
            assigneeName: null,
            priority: 'medium',
          ),
        ],
      );

      await tester.pumpWidget(_app(repository: repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Available to Claim'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Medium'));
      await tester.pumpAndSettle();
      expect(find.text('High'), findsNothing);
      expect(repository.lastUpdatedPriority, isNull);

      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();
      expect(find.text('OK'), findsNothing);
      expect(repository.lastProgressUpdatedDueDate, isNull);
    },
  );

  testWidgets("an unclaimed task can't be dragged to a different column", (
    tester,
  ) async {
    final repository = FakeTaskRepository(
      claimableTasks: [
        buildTestTask(
          assigneeEmployeeId: null,
          assigneeName: null,
          status: TaskStatus.todo,
          title: 'Unclaimed task',
        ),
      ],
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Available to Claim'));
    await tester.pumpAndSettle();

    final cardCenter = tester.getCenter(find.text('Unclaimed task'));
    final inProgressColumnCenter = tester.getCenter(find.text('In Progress'));

    final gesture = await tester.startGesture(cardCenter);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(inProgressColumnCenter);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(repository.lastProgressUpdatedId, isNull);
  });

  testWidgets('hides the Archived toggle for a plain employee', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Archived'), findsNothing);
  });

  testWidgets(
    'a tasks.manage holder can toggle Archived to see only archived tasks',
    (tester) async {
      final admin = const AuthUser(
        id: 'admin-1',
        email: 'admin@zeracreative.com',
        role: 'Super Admin',
        permissions: ['tasks.manage'],
      );
      final repository = FakeTaskRepository(
        myTasks: [
          buildTestTask(id: 'task-active', title: 'Active task'),
          buildTestTask(
            id: 'task-archived',
            title: 'Archived task',
            isArchived: true,
          ),
        ],
      );

      await tester.pumpWidget(_app(user: admin, repository: repository));
      await tester.pumpAndSettle();

      expect(find.text('Active task'), findsOneWidget);
      expect(find.text('Archived task'), findsNothing);

      await tester.tap(find.text('Archived'));
      await tester.pumpAndSettle();

      expect(find.text('Active task'), findsNothing);
      expect(find.text('Archived task'), findsOneWidget);
    },
  );

  testWidgets('tapping the archive icon on a card archives the task, for a '
      'tasks.manage holder', (tester) async {
    final admin = const AuthUser(
      id: 'admin-1',
      email: 'admin@zeracreative.com',
      role: 'Super Admin',
      permissions: ['tasks.manage'],
    );
    final repository = FakeTaskRepository(
      myTasks: [buildTestTask(id: 'task-1', title: 'Some task')],
    );

    await tester.pumpWidget(_app(user: admin, repository: repository));
    await tester.pumpAndSettle();

    // Scoped to the board area — the header's Archived toggle chip also
    // uses this same icon as its avatar, so a bare `find.byIcon` would be
    // ambiguous.
    await tester.tap(
      find.descendant(
        of: find.byType(TabBarView),
        matching: find.byIcon(Icons.archive_outlined),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.lastArchivedTaskId, 'task-1');
    expect(repository.lastArchivedIsArchived, isTrue);
  });

  testWidgets('hides the card archive icon for a plain employee', (
    tester,
  ) async {
    final repository = FakeTaskRepository(
      myTasks: [buildTestTask(id: 'task-1', title: 'Some task')],
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.archive_outlined), findsNothing);
  });
}
