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
import 'package:zera_erp/features/tasks/presentation/pages/task_detail_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_task.dart';

Widget _app({
  AuthUser user = testAuthUser,
  List<Department> departments = const [],
  required FakeTaskRepository repository,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(user)),
      ),
      employeeRepositoryProvider.overrideWithValue(
        FakeEmployeeRepository(departments: departments),
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

  testWidgets('changing the status dropdown updates the task status', (
    tester,
  ) async {
    final repository = FakeTaskRepository(
      taskById: buildTestTask(status: TaskStatus.todo),
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('In Progress').last);
    await tester.pumpAndSettle();

    expect(repository.lastStatusUpdatedId, 'task-1');
    expect(repository.lastStatusUpdatedStatus, TaskStatus.inProgress);
  });

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

    await tester.enterText(find.byType(TextField), 'On it.');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Post'));
    await tester.tap(find.widgetWithText(FilledButton, 'Post'));
    await tester.pumpAndSettle();

    expect(repository.lastCommentedId, 'task-1');
    expect(repository.lastCommentBody, 'On it.');
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

  testWidgets('shows the Edit button for the assigner', (tester) async {
    final repository = FakeTaskRepository(
      taskById: buildTestTask(assignedByUserId: 'user-1'),
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('hides the Edit button for a plain assignee viewer', (
    tester,
  ) async {
    final repository = FakeTaskRepository(
      taskById: buildTestTask(
        assigneeEmployeeId: 'employee-1',
        assignedByUserId: 'someone-else',
        departmentId: 'dept-1',
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
  });
}
