import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/entities/department.dart';
import 'package:zera_erp/features/employee/domain/entities/employee.dart';
import 'package:zera_erp/features/employee/presentation/widgets/employee_avatar.dart';
import 'package:zera_erp/features/tasks/application/task_providers.dart';
import 'package:zera_erp/features/tasks/domain/entities/task_status.dart';
import 'package:zera_erp/features/tasks/presentation/pages/task_detail_page.dart';
import 'package:zera_erp/shared/models/named_ref.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_task.dart';

Widget _app({
  AuthUser user = testAuthUser,
  List<Department> departments = const [],
  List<Employee> employees = const [],
  Employee? me,
  required FakeTaskRepository repository,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(user)),
      ),
      employeeRepositoryProvider.overrideWithValue(
        FakeEmployeeRepository(
          departments: departments,
          employees: employees,
          me: me,
        ),
      ),
      taskRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(home: TaskDetailPage(taskId: 'task-1')),
  );
}

void main() {
  testWidgets('shows the task fields', (tester) async {
    final repository = FakeTaskRepository(
      taskById: buildTestTask(
        title: 'Write report',
        assigneeName: 'Jane Doe',
        assignedByName: 'Manager Person',
        departmentName: 'Engineering',
      ),
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Write report'), findsOneWidget);
    expect(find.text('Assigned to Jane Doe'), findsOneWidget);
    expect(find.text('Assigned by Manager Person'), findsOneWidget);
    expect(find.text('Department: Engineering'), findsOneWidget);
    // One avatar for the assignee, one for the assigner.
    expect(find.byType(EmployeeAvatar), findsNWidgets(2));
    expect(find.text('Quarterly summary'), findsOneWidget);
  });

  testWidgets(
    'shows status as a read-only badge, with no separate progress-remarks '
    'control — a single Comments section is the only way to post a comment',
    (tester) async {
      final repository = FakeTaskRepository(
        taskById: buildTestTask(status: TaskStatus.inProgress),
      );

      await tester.pumpWidget(_app(repository: repository));
      await tester.pumpAndSettle();

      expect(find.text('In Progress'), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsNothing);
      expect(find.byKey(const Key('progress-remarks-input')), findsNothing);
      expect(find.text('Save remarks'), findsNothing);
      expect(find.text('Comments'), findsOneWidget);
      expect(find.text('Discussion'), findsNothing);
      expect(find.text('Progress'), findsNothing);
    },
  );

  testWidgets(
    'highlights the due date, in red once overdue on a still-open task',
    (tester) async {
      final repository = FakeTaskRepository(
        taskById: buildTestTask(
          dueDate: '2020-01-01',
          status: TaskStatus.inProgress,
        ),
      );

      await tester.pumpWidget(_app(repository: repository));
      await tester.pumpAndSettle();

      expect(find.textContaining('Overdue'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    },
  );

  testWidgets('shows existing comments and posts a new one', (tester) async {
    final repository = FakeTaskRepository(
      taskById: buildTestTask(),
      comments: [
        buildTestTaskComment(authorName: 'Jane Doe', body: 'Looks good.'),
      ],
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Looks good.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('comment-input')), 'On it.');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Post'));
    await tester.tap(find.widgetWithText(FilledButton, 'Post'));
    await tester.pumpAndSettle();

    expect(repository.lastCommentedId, 'task-1');
    expect(repository.lastCommentBody, 'On it.');
  });

  testWidgets('an unclaimed task also shows the merged Comments section, not a '
      'separate Discussion card', (tester) async {
    final repository = FakeTaskRepository(
      taskById: buildTestTask(
        assigneeEmployeeId: null,
        assigneeName: null,
        departmentId: 'dept-1',
        departmentName: 'Engineering',
      ),
    );

    await tester.pumpWidget(
      _app(
        repository: repository,
        me: buildTestEmployee(
          id: 'someone-else-entirely',
          department: const NamedRef(id: 'dept-2', name: 'Sales'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Comments'), findsOneWidget);
    expect(find.text('Discussion'), findsNothing);
  });

  testWidgets('shows history entries', (tester) async {
    final repository = FakeTaskRepository(
      taskById: buildTestTask(),
      history: [
        buildTestTaskAuditLogEntry(
          fieldLabel: 'Created',
          newValue: 'Assigned to Jane Doe',
        ),
        buildTestTaskAuditLogEntry(
          fieldLabel: 'Status',
          oldValue: TaskStatus.todo,
          newValue: TaskStatus.inProgress,
          actorName: 'Jane Doe',
        ),
      ],
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(
      find.text('Jane Doe created this task — Assigned to Jane Doe'),
      findsOneWidget,
    );
    expect(
      find.text('Jane Doe changed Status from To Do to In Progress'),
      findsOneWidget,
    );
  });

  testWidgets(
    'the assigner can edit the title directly on the page — no separate '
    'Edit page, and no Edit button at all',
    (tester) async {
      final repository = FakeTaskRepository(
        taskById: buildTestTask(assignedByUserId: 'user-1', title: 'Old title'),
      );

      await tester.pumpWidget(_app(repository: repository));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsNothing);
      final titleField = find.widgetWithText(TextField, 'Old title');
      expect(titleField, findsOneWidget);

      await tester.enterText(titleField, 'New title');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(repository.lastUpdatedId, 'task-1');
      expect(repository.lastUpdatedTitle, 'New title');
    },
  );

  testWidgets('a tasks.manage holder can edit priority directly', (
    tester,
  ) async {
    final repository = FakeTaskRepository(
      taskById: buildTestTask(
        assignedByUserId: 'someone-else',
        priority: 'medium',
      ),
    );

    await tester.pumpWidget(
      _app(
        user: const AuthUser(
          id: 'admin-1',
          email: 'admin@zeracreative.com',
          role: 'Super Admin',
          permissions: ['tasks.manage'],
        ),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Medium'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('High').last);
    await tester.pumpAndSettle();

    expect(repository.lastUpdatedId, 'task-1');
    expect(repository.lastUpdatedPriority, 'high');
  });

  testWidgets(
    "the assignee's department head (a Team Lead) can edit the due date "
    'without tasks.manage',
    (tester) async {
      final repository = FakeTaskRepository(
        taskById: buildTestTask(
          assigneeEmployeeId: 'employee-1',
          assignedByUserId: 'someone-else',
          departmentId: 'dept-1',
          dueDate: '2026-09-15',
        ),
      );

      await tester.pumpWidget(
        _app(
          repository: repository,
          departments: const [
            Department(
              id: 'dept-1',
              name: 'Engineering',
              headEmployeeId: 'employee-1',
            ),
          ],
        ),
      );
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('30').last);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(repository.lastUpdatedId, 'task-1');
      expect(repository.lastUpdatedDueDate, '2026-09-30');

      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'a plain assignee viewer sees read-only fields, not editable ones',
    (tester) async {
      final repository = FakeTaskRepository(
        taskById: buildTestTask(
          assigneeEmployeeId: 'employee-1',
          assignedByUserId: 'someone-else',
          departmentId: 'dept-1',
          title: 'Read-only title',
        ),
      );

      await tester.pumpWidget(
        _app(
          repository: repository,
          departments: const [
            Department(
              id: 'dept-1',
              name: 'Engineering',
              headEmployeeId: 'someone-else-entirely',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsNothing);
      expect(find.widgetWithText(TextField, 'Read-only title'), findsNothing);
      expect(find.text('Read-only title'), findsOneWidget);
    },
  );

  testWidgets(
    'a member of the task\'s own team sees an Accept button and claiming it '
    'calls the repository',
    (tester) async {
      final repository = FakeTaskRepository(
        taskById: buildTestTask(
          assigneeEmployeeId: null,
          assigneeName: null,
          departmentId: 'dept-1',
          departmentName: 'Engineering',
        ),
      );

      await tester.pumpWidget(
        _app(
          repository: repository,
          me: buildTestEmployee(
            id: 'employee-1',
            department: const NamedRef(id: 'dept-1', name: 'Engineering'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('This task is assigned to Engineering'),
        findsOneWidget,
      );
      expect(find.text('Accept this task'), findsOneWidget);

      await tester.tap(find.text('Accept this task'));
      await tester.pumpAndSettle();

      expect(repository.lastClaimedId, 'task-1');
    },
  );

  testWidgets(
    "the team's head can pick a specific member for an unclaimed task",
    (tester) async {
      final repository = FakeTaskRepository(
        taskById: buildTestTask(
          assigneeEmployeeId: null,
          assigneeName: null,
          departmentId: 'dept-1',
          departmentName: 'Engineering',
        ),
      );

      await tester.pumpWidget(
        _app(
          repository: repository,
          me: buildTestEmployee(
            id: 'head-1',
            department: const NamedRef(id: 'dept-1', name: 'Engineering'),
          ),
          employees: [
            buildTestEmployee(
              id: 'employee-2',
              fullName: 'Target Person',
              department: const NamedRef(id: 'dept-1', name: 'Engineering'),
            ),
          ],
          departments: const [
            Department(
              id: 'dept-1',
              name: 'Engineering',
              headEmployeeId: 'head-1',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Assign a team member'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(
          DropdownButtonFormField<String>,
          'Assign a team member',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Target Person').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Assign'));
      await tester.pumpAndSettle();

      expect(repository.lastAssignedMemberTaskId, 'task-1');
      expect(repository.lastAssignedMemberEmployeeId, 'employee-2');
    },
  );

  testWidgets('hides the archive action for a viewer without tasks.manage', (
    tester,
  ) async {
    final repository = FakeTaskRepository(taskById: buildTestTask());

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.archive_outlined), findsNothing);
    expect(find.byIcon(Icons.unarchive_outlined), findsNothing);
  });

  testWidgets('lets a tasks.manage holder archive the task from the app bar', (
    tester,
  ) async {
    final admin = const AuthUser(
      id: 'admin-1',
      email: 'admin@zeracreative.com',
      role: 'Super Admin',
      permissions: ['tasks.manage'],
    );
    final repository = FakeTaskRepository(taskById: buildTestTask());

    await tester.pumpWidget(_app(user: admin, repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Archived'), findsNothing);

    await tester.tap(find.byIcon(Icons.archive_outlined));
    await tester.pumpAndSettle();

    expect(repository.lastArchivedTaskId, 'task-1');
    expect(repository.lastArchivedIsArchived, isTrue);
  });

  testWidgets(
    "shows an 'Archived' badge and an unarchive action for an already-"
    'archived task, for a tasks.manage holder',
    (tester) async {
      final admin = const AuthUser(
        id: 'admin-1',
        email: 'admin@zeracreative.com',
        role: 'Super Admin',
        permissions: ['tasks.manage'],
      );
      final repository = FakeTaskRepository(
        taskById: buildTestTask(isArchived: true),
      );

      await tester.pumpWidget(_app(user: admin, repository: repository));
      await tester.pumpAndSettle();

      expect(find.text('Archived'), findsOneWidget);
      expect(find.byIcon(Icons.unarchive_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.unarchive_outlined));
      await tester.pumpAndSettle();

      expect(repository.lastArchivedTaskId, 'task-1');
      expect(repository.lastArchivedIsArchived, isFalse);
    },
  );
}
