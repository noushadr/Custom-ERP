import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/clients/application/clients_providers.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/entities/department.dart';
import 'package:zera_erp/features/employee/domain/entities/employee.dart';
import 'package:zera_erp/features/tasks/application/task_providers.dart';
import 'package:zera_erp/features/tasks/domain/entities/task_priority.dart';
import 'package:zera_erp/features/tasks/presentation/pages/task_editor_page.dart';
import 'package:zera_erp/shared/models/named_ref.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_clients.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_task.dart';

Widget _app({
  AuthUser user = testAuthUser,
  List<Employee> employees = const [],
  List<Department> departments = const [],
  FakeTaskRepository? repository,
  FakeClientsRepository? clientsRepository,
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
      clientsRepositoryProvider.overrideWithValue(
        clientsRepository ?? FakeClientsRepository(),
      ),
    ],
    child: MaterialApp(
      home: child ?? const TaskEditorPage(),
      // Wide enough to trigger the two-column layout consistently across
      // every test below, matching how this page is actually used (a
      // desktop admin app) — narrower-viewport stacking is covered by its
      // own dedicated test.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(size: const Size(1200, 900)),
        child: child!,
      ),
    ),
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

  testWidgets('priority defaults to Low, shown as selection buttons — no '
      'dropdown', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.byType(ChoiceChip), findsNWidgets(4));

    final lowChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Low'),
    );
    expect(lowChip.selected, isTrue);
    final mediumChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Medium'),
    );
    expect(mediumChip.selected, isFalse);
  });

  testWidgets('tapping a priority chip selects it', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Urgent'));
    await tester.pumpAndSettle();

    final urgentChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Urgent'),
    );
    expect(urgentChip.selected, isTrue);
  });

  testWidgets('a plain employee gets only a team search field, no toggle, no '
      'employee picker', (tester) async {
    final repository = FakeTaskRepository();

    await tester.pumpWidget(
      _app(
        departments: const [Department(id: 'dept-1', name: 'Engineering')],
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Person'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Team'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Ship the release',
    );
    await tester.tap(find.widgetWithText(TextFormField, 'Team'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Engineering').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('task-due-date')));
    await tester.tap(find.byKey(const Key('task-due-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Create Task'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create Task'));
    await tester.pumpAndSettle();

    expect(repository.lastCreatedAssigneeEmployeeId, isNull);
    expect(repository.lastCreatedDepartmentId, 'dept-1');
  });

  testWidgets('a tasks.manage holder can toggle to Team instead of Person', (
    tester,
  ) async {
    final repository = FakeTaskRepository();

    await tester.pumpWidget(
      _app(
        user: const AuthUser(
          id: 'admin-1',
          email: 'admin@zeracreative.com',
          role: 'Super Admin',
          permissions: ['tasks.manage'],
        ),
        departments: const [Department(id: 'dept-1', name: 'Engineering')],
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Person'), findsOneWidget);
    expect(find.text('Team'), findsWidgets);
    await tester.tap(find.text('Team').first);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Team'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Assignee'), findsNothing);
  });

  testWidgets("restricts the assignee search field to a department head's own "
      'department', (tester) async {
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

    await tester.tap(find.widgetWithText(TextFormField, 'Assignee'));
    await tester.pumpAndSettle();

    expect(find.text('In Department'), findsOneWidget);
    expect(find.text('Outside Department'), findsNothing);
  });

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

    await tester.tap(find.widgetWithText(TextFormField, 'Assignee'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Target Person').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'High'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('task-due-date')));
    await tester.tap(find.byKey(const Key('task-due-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Create Task'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create Task'));
    await tester.pumpAndSettle();

    expect(repository.lastCreatedTitle, 'Ship the release');
    expect(repository.lastCreatedAssigneeEmployeeId, 'employee-2');
    expect(repository.lastCreatedPriority, TaskPriority.high);
  });

  testWidgets(
    'searching and selecting a project fills in the client/project field',
    (tester) async {
      final repository = FakeTaskRepository();
      final clientsRepository = FakeClientsRepository(
        projects: [
          buildTestProject(
            id: 'project-1',
            name: 'Website Revamp',
            clientName: 'Acme Co',
          ),
        ],
      );

      await tester.pumpWidget(
        _app(
          user: const AuthUser(
            id: 'admin-1',
            email: 'admin@zeracreative.com',
            role: 'Super Admin',
            permissions: ['tasks.manage'],
          ),
          employees: [buildTestEmployee(id: 'employee-2', fullName: 'Jane')],
          repository: repository,
          clientsRepository: clientsRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Kickoff call',
      );

      await tester.ensureVisible(
        find.widgetWithText(TextFormField, 'Client / Project (optional)'),
      );
      await tester.tap(
        find.widgetWithText(TextFormField, 'Client / Project (optional)'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Website Revamp — Acme Co'), findsOneWidget);
      await tester.tap(find.text('Website Revamp — Acme Co'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextFormField, 'Assignee'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jane').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('task-due-date')));
      await tester.tap(find.byKey(const Key('task-due-date')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Create Task'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create Task'));
      await tester.pumpAndSettle();

      expect(repository.lastCreatedTitle, 'Kickoff call');
      expect(repository.lastCreatedProjectId, 'project-1');
    },
  );

  testWidgets('pre-fills fields when editing an existing task', (tester) async {
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
    final highChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'High'),
    );
    expect(highChip.selected, isTrue);
  });

  testWidgets('stacks into a single column on a narrow screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => PresetAuthController(AuthAuthenticated(testAuthUser)),
          ),
          employeeRepositoryProvider.overrideWithValue(
            FakeEmployeeRepository(),
          ),
          taskRepositoryProvider.overrideWithValue(FakeTaskRepository()),
          clientsRepositoryProvider.overrideWithValue(FakeClientsRepository()),
        ],
        child: const MaterialApp(home: TaskEditorPage()),
      ),
    );
    await tester.binding.setSurfaceSize(const Size(420, 800));
    await tester.pumpAndSettle();

    final titleTop = tester.getTopLeft(
      find.widgetWithText(TextFormField, 'Title'),
    );
    final dueDateTop = tester.getTopLeft(
      find.byKey(const Key('task-due-date')),
    );
    expect(dueDateTop.dy, greaterThan(titleTop.dy));

    await tester.binding.setSurfaceSize(null);
  });
}
