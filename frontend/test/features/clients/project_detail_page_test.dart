import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/clients/application/clients_providers.dart';
import 'package:zera_erp/features/clients/domain/entities/project_refs.dart';
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
  testWidgets('shows services, departments, and employees', (tester) async {
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          projects: [
            buildTestProject(
              name: 'Website Revamp',
              services: const [ProjectServiceRef(id: 's1', name: 'SEO')],
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
    expect(find.text('SEO'), findsOneWidget);
    expect(find.text('Engineering'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
  });

  testWidgets(
    'shows only a plain "Package" section — never "SEO Details" or its '
    'other fields — regardless of the project\'s actual service',
    (tester) async {
      await tester.pumpWidget(
        _app(
          repository: FakeClientsRepository(
            projects: [
              buildTestProject(
                name: 'SMM Retainer',
                services: const [ProjectServiceRef(id: 's1', name: 'SMM')],
                packageName: 'GROWTH +',
                // Legacy data some older projects still carry — none of
                // this should render any more.
                backlinksTarget: '50',
                seoSheetName: 'Old Sheet',
                projectFolderName: 'Old Folder',
                workingEmailAccount: 'old@client.test',
                ahrefsAccount: 'old-ahrefs',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SEO Details'), findsNothing);
      expect(find.text('Package'), findsOneWidget);
      expect(find.text('GROWTH +'), findsOneWidget);
      expect(find.text('Backlinks target'), findsNothing);
      expect(find.text('50'), findsNothing);
      expect(find.text('SEO sheet'), findsNothing);
      expect(find.text('Old Sheet'), findsNothing);
      expect(find.text('Project folder'), findsNothing);
      expect(find.text('Old Folder'), findsNothing);
      expect(find.text('Working email account'), findsNothing);
      expect(find.text('old@client.test'), findsNothing);
      expect(find.text('Ahrefs account'), findsNothing);
      expect(find.text('old-ahrefs'), findsNothing);
      expect(
        find.textContaining('kept in the team password manager'),
        findsNothing,
      );
    },
  );

  testWidgets('shows no Package section when the project has none set', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          projects: [buildTestProject(packageName: null)],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Package'), findsNothing);
  });

  testWidgets(
    'the project name renders bold and large, with the client name as a '
    'smaller subtitle underneath — never an end/"due" date',
    (tester) async {
      await tester.pumpWidget(
        _app(
          repository: FakeClientsRepository(
            projects: [
              buildTestProject(
                name: 'SMM Retainer',
                clientName: 'Acme Co',
                endDate: '2026-12-31',
              ),
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
}
