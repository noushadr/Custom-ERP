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
