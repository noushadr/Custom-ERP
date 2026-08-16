import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/entities/department.dart';
import 'package:zera_erp/features/employee/domain/entities/team.dart';
import 'package:zera_erp/features/employee/domain/exceptions/employee_exception.dart';
import 'package:zera_erp/features/employee/presentation/pages/teams_page.dart';
import 'package:zera_erp/shared/models/named_ref.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';

Widget _app(FakeEmployeeRepository repository) {
  final user = AuthUser(
    id: 'user-1',
    email: 'jane.doe@zeracreative.com',
    role: 'HR/Manager',
    permissions: const ['teams.manage'],
  );

  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(user)),
      ),
      employeeRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(home: TeamsPage()),
  );
}

void main() {
  testWidgets('shows the list of teams with their department and lead', (
    tester,
  ) async {
    final leadEmployee = buildTestEmployee(
      id: 'employee-1',
      fullName: 'Mona Manager',
    );
    final repository = FakeEmployeeRepository(
      employees: [leadEmployee],
      teamsManagement: const [
        Team(
          id: 'team-1',
          name: 'Platform',
          departmentId: 'department-1',
          departmentName: 'Engineering',
          leadEmployeeId: 'employee-1',
        ),
        Team(id: 'team-2', name: 'Web', departmentId: 'department-1'),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Platform'), findsOneWidget);
    expect(find.text('Department: Engineering'), findsOneWidget);
    expect(find.text('Lead: Mona Manager'), findsOneWidget);
    expect(find.text('Web'), findsOneWidget);
    expect(find.text('No team lead assigned'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no teams', (tester) async {
    final repository = FakeEmployeeRepository();

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No active teams. Turn on "Show archived" to see archived ones.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('adding a team calls createTeam and refreshes', (tester) async {
    final repository = FakeEmployeeRepository(
      departments: const [Department(id: 'department-1', name: 'Engineering')],
      teamsManagement: const [
        Team(id: 'team-1', name: 'Platform', departmentId: 'department-1'),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Design');
    await tester.tap(find.byType(DropdownButtonFormField<String?>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Engineering').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add team').last);
    await tester.pumpAndSettle();

    expect(repository.lastCreateTeamInput?.name, 'Design');
    expect(repository.lastCreateTeamInput?.departmentId, 'department-1');
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('editing a team pre-fills the form and saves changes', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(
      departments: const [Department(id: 'department-1', name: 'Engineering')],
      teamsManagement: const [
        Team(id: 'team-1', name: 'Platform', departmentId: 'department-1'),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Edit team'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Platform'),
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField).first, 'Platform Team');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(repository.lastUpdateTeamInput?.id, 'team-1');
    expect(repository.lastUpdateTeamInput?.name, 'Platform Team');
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('shows the number of employees assigned to each team', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(
      employees: [
        buildTestEmployee(
          id: 'employee-1',
          fullName: 'Ravi Report',
          team: const NamedRef(id: 'team-1', name: 'Platform'),
        ),
      ],
      teamsManagement: const [
        Team(id: 'team-1', name: 'Platform', departmentId: 'department-1'),
        Team(id: 'team-2', name: 'Web', departmentId: 'department-1'),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('1 employee'), findsOneWidget);
    expect(find.text('0 employees'), findsOneWidget);
  });

  testWidgets('archiving a team calls setTeamArchived', (tester) async {
    final repository = FakeEmployeeRepository(
      teamsManagement: const [
        Team(id: 'team-1', name: 'Platform', departmentId: 'department-1'),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(repository.lastSetTeamArchivedInput?.id, 'team-1');
    expect(repository.lastSetTeamArchivedInput?.isArchived, true);
  });

  testWidgets('deleting a team asks for confirmation before calling '
      'deleteTeam', (tester) async {
    final repository = FakeEmployeeRepository(
      teamsManagement: const [
        Team(id: 'team-1', name: 'Platform', departmentId: 'department-1'),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete team?'), findsOneWidget);
    expect(repository.lastDeleteTeamId, isNull);

    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(repository.lastDeleteTeamId, 'team-1');
  });

  testWidgets(
    'shows the conflict message when a team still has employees assigned',
    (tester) async {
      final repository = FakeEmployeeRepository(
        teamsManagement: const [
          Team(id: 'team-1', name: 'Platform', departmentId: 'department-1'),
        ],
        deleteTeamError: const EmployeeException(
          'Cannot delete a team that still has employees assigned. Archive '
          'it instead.',
        ),
      );

      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Cannot delete a team that still has employees assigned. Archive '
          'it instead.',
        ),
        findsOneWidget,
      );
    },
  );
}
