import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/clients/application/clients_providers.dart';
import 'package:zera_erp/features/clients/domain/entities/project_refs.dart';
import 'package:zera_erp/features/clients/domain/entities/project_type.dart';
import 'package:zera_erp/features/clients/presentation/pages/project_detail_page.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/tasks/application/task_providers.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_clients.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_task.dart';

const _superAdmin = AuthUser(
  id: 'admin-1',
  email: 'admin@zeracreative.com',
  role: 'Super Admin',
  permissions: ['clients.manage'],
);

Widget _app({
  required FakeClientsRepository repository,
  FakeTaskRepository? taskRepository,
  String projectId = 'project-1',
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(_superAdmin)),
      ),
      employeeRepositoryProvider.overrideWithValue(FakeEmployeeRepository()),
      clientsRepositoryProvider.overrideWithValue(repository),
      taskRepositoryProvider.overrideWithValue(
        taskRepository ?? FakeTaskRepository(),
      ),
    ],
    child: MaterialApp(home: ProjectDetailPage(projectId: projectId)),
  );
}

void main() {
  testWidgets('shows departments and employees', (tester) async {
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          projects: [
            buildTestProject(
              name: 'Website Revamp',
              targetDepartments: const [
                ProjectDepartmentRef(id: 'd1', name: 'Engineering'),
              ],
              assignedEmployees: const [
                ProjectEmployeeRef(
                  id: 'e1',
                  fullName: 'Jane Doe',
                  photoUrl: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Website Revamp'), findsOneWidget);
    expect(find.text('Engineering'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
  });

  testWidgets('a one-time project shows its deadline and owner, not a renewal '
      'date, and no Package/Services sections', (tester) async {
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          projects: [
            buildTestProject(
              name: 'Site Build',
              type: ProjectType.oneTime,
              startDate: '2026-02-15',
              endDate: '2026-06-30',
              renewalDate: '2026-07-15',
              accountManager: const ProjectEmployeeRef(
                id: 'e1',
                fullName: 'Jane Owner',
                photoUrl: null,
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deadline Jun 30, 2026'), findsOneWidget);
    expect(find.textContaining('Renews'), findsNothing);
    expect(find.text('Owner Jane Owner'), findsOneWidget);
    expect(find.text('Package'), findsNothing);
    expect(find.text('Services'), findsNothing);
  });

  testWidgets('a retainer shows its renewal date, not a deadline', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          projects: [
            buildTestProject(
              name: 'SEO Retainer',
              type: ProjectType.retainer,
              endDate: '2026-06-30',
              renewalDate: '2026-07-15',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Renews Jul 15, 2026'), findsOneWidget);
    expect(find.textContaining('Deadline'), findsNothing);
  });

  testWidgets(
    'the project name renders bold and large, with the client name as a '
    'smaller subtitle underneath — never an end/"due" date',
    (tester) async {
      await tester.pumpWidget(
        _app(
          repository: FakeClientsRepository(
            projects: [
              buildTestProject(name: 'SMM Retainer', clientName: 'Acme Co'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nameText = tester.widget<Text>(find.text('SMM Retainer'));
      expect(nameText.style?.fontWeight, FontWeight.bold);
      expect(
        nameText.style?.fontSize,
        Theme.of(
          tester.element(find.text('SMM Retainer')),
        ).textTheme.headlineMedium?.fontSize,
      );

      expect(find.text('Acme Co'), findsOneWidget);
      expect(find.textContaining('End'), findsNothing);
    },
  );

  testWidgets('shows linked tasks and an empty state when there are none', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(repository: FakeClientsRepository(projects: [buildTestProject()])),
    );
    await tester.pumpAndSettle();

    expect(find.text('No tasks linked to this project yet.'), findsOneWidget);
  });

  testWidgets('shows a linked task in the Tasks section', (tester) async {
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(projects: [buildTestProject()]),
        taskRepository: FakeTaskRepository(
          tasksByProject: [buildTestTask(title: 'Design homepage')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Design homepage'), findsOneWidget);
    expect(find.text('New Task'), findsOneWidget);
  });

  testWidgets(
    'shows an Archive button for an active project, and archiving it calls '
    'the repository',
    (tester) async {
      final repository = FakeClientsRepository(
        projects: [buildTestProject(name: 'Website Revamp')],
      );
      await tester.pumpWidget(_app(repository: repository));
      await tester.pumpAndSettle();

      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Unarchive'), findsNothing);
      expect(find.text('Archived'), findsNothing);

      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(repository.lastUpdateProjectIsArchived, isTrue);
    },
  );

  testWidgets(
    'shows an Unarchive button and an Archived badge for an archived project',
    (tester) async {
      await tester.pumpWidget(
        _app(
          repository: FakeClientsRepository(
            projects: [buildTestProject(name: 'Old Project', isArchived: true)],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unarchive'), findsOneWidget);
      expect(find.text('Archive'), findsNothing);
      expect(find.text('Archived'), findsOneWidget);
    },
  );
}
