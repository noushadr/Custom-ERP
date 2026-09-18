import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/entities/department.dart';
import 'package:zera_erp/features/goals/application/goal_providers.dart';
import 'package:zera_erp/features/goals/presentation/pages/goals_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_goal.dart';

Widget _app({
  String role = 'Employee',
  List<String> permissions = const [],
  FakeGoalRepository? goalRepository,
  FakeEmployeeRepository? employeeRepository,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(
          AuthAuthenticated(
            AuthUser(
              id: 'user-1',
              email: 'jane.doe@zeracreative.com',
              role: role,
              permissions: permissions,
            ),
          ),
        ),
      ),
      goalRepositoryProvider.overrideWithValue(
        goalRepository ?? FakeGoalRepository(),
      ),
      employeeRepositoryProvider.overrideWithValue(
        employeeRepository ?? FakeEmployeeRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: GoalsPage())),
  );
}

void main() {
  testWidgets(
    'a plain employee sees My Goals and can add a goal for themselves with no approval',
    (tester) async {
      final goalRepository = FakeGoalRepository(
        mine: [buildTestGoal(employeeName: 'Jane Doe')],
      );
      await tester.pumpWidget(_app(goalRepository: goalRepository));
      await tester.pumpAndSettle();

      expect(find.text('My Goals'), findsOneWidget);
      // No employee/department picker or search/filter row — it's always
      // implicitly "for me".
      expect(find.text('Search by employee name'), findsNothing);
      expect(find.text('Individual'), findsNothing);

      await tester.tap(find.text('Add Goal'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Goal'),
        'Learn Flutter',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(goalRepository.lastCreatedWasSelfScoped, isTrue);
      expect(goalRepository.lastCreatedTitle, 'Learn Flutter');
    },
  );

  testWidgets(
    "an employee can edit their own goal's achievement percentage and archive it",
    (tester) async {
      final goalRepository = FakeGoalRepository(
        mine: [buildTestGoal(id: 'goal-9', achievementPercentage: 10)],
      );
      await tester.pumpWidget(_app(goalRepository: goalRepository));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Achieved'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(goalRepository.lastActionWasSelfScoped, isTrue);
      expect(goalRepository.lastUpdatedAchievementPercentage, 10);

      await tester.tap(find.byTooltip('Archive'));
      await tester.pumpAndSettle();

      expect(goalRepository.lastArchivedGoalId, 'goal-9');
      expect(goalRepository.lastActionWasSelfScoped, isTrue);
    },
  );

  testWidgets(
    'an Admin/HR holder sees All Goals and can add a goal for one employee',
    (tester) async {
      final goalRepository = FakeGoalRepository(
        all: [buildTestGoal(employeeName: 'Babar Hussain')],
      );
      await tester.pumpWidget(
        _app(
          permissions: ['goals.manage'],
          goalRepository: goalRepository,
          employeeRepository: FakeEmployeeRepository(
            employees: [buildTestEmployee(id: 'employee-2', fullName: 'Aamna Irfan')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All Goals'), findsOneWidget);
      expect(find.text('Babar Hussain'), findsOneWidget);
      expect(find.text('English speaking'), findsOneWidget);

      await tester.tap(find.text('Add Goal'));
      await tester.pumpAndSettle();

      expect(find.text('Individual'), findsOneWidget);
      expect(find.text('Whole department'), findsOneWidget);

      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Employee'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aamna Irfan').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Goal'),
        'English speaking',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(goalRepository.lastCreatedEmployeeId, 'employee-2');
      expect(goalRepository.lastCreatedTitle, 'English speaking');
      expect(goalRepository.lastActionWasManagerScoped, isFalse);
    },
  );

  testWidgets(
    'an Admin/HR holder can bulk-assign a goal to a whole department',
    (tester) async {
      final goalRepository = FakeGoalRepository();
      await tester.pumpWidget(
        _app(
          permissions: ['goals.manage'],
          goalRepository: goalRepository,
          employeeRepository: FakeEmployeeRepository(
            departments: [
              const Department(id: 'dept-seo', name: 'SEO'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Goal'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Whole department'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'Department'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('SEO').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Goal'),
        'English speaking',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(goalRepository.lastBulkDepartmentId, 'dept-seo');
      expect(goalRepository.lastBulkTitle, 'English speaking');
    },
  );

  testWidgets(
    'a Team Lead sees both their own goals and their team\'s, with no department filter',
    (tester) async {
      final goalRepository = FakeGoalRepository(
        mine: [
          buildTestGoal(
            id: 'goal-mine',
            employeeId: 'employee-1',
            employeeName: 'Jane Doe',
          ),
        ],
        team: [
          buildTestGoal(
            id: 'goal-team',
            employeeId: 'report-1',
            employeeName: 'Babar Hussain',
          ),
        ],
      );
      await tester.pumpWidget(
        _app(
          role: 'Team Lead',
          goalRepository: goalRepository,
          employeeRepository: FakeEmployeeRepository(
            directReports: [
              buildTestEmployee(id: 'report-1', fullName: 'Babar Hussain'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("My Goals & Team's Goals"), findsOneWidget);
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('Babar Hussain'), findsOneWidget);
      // No admin-only "Individual"/"Whole department" toggle, and no
      // department filter — a Team Lead's list is always just this small,
      // already-scoped set.
      expect(find.text('Whole department'), findsNothing);
      expect(
        find.widgetWithText(DropdownButtonFormField<String?>, 'Department'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'a Team Lead can add a goal for a direct report, or for themselves via "Myself"',
    (tester) async {
      final goalRepository = FakeGoalRepository();
      await tester.pumpWidget(
        _app(
          role: 'Team Lead',
          goalRepository: goalRepository,
          employeeRepository: FakeEmployeeRepository(
            directReports: [
              buildTestEmployee(id: 'report-1', fullName: 'Babar Hussain'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Goal'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Employee'));
      await tester.pumpAndSettle();
      expect(find.text('Myself'), findsOneWidget);
      await tester.tap(find.text('Babar Hussain').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Goal'),
        'English speaking',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(goalRepository.lastCreatedEmployeeId, 'report-1');
      expect(goalRepository.lastActionWasManagerScoped, isTrue);

      await tester.tap(find.text('Add Goal'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Employee'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Myself').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Goal'),
        'Public speaking',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(goalRepository.lastCreatedWasSelfScoped, isTrue);
      expect(goalRepository.lastCreatedTitle, 'Public speaking');
    },
  );

  testWidgets('archiving a goal as Admin/HR calls the unscoped archive', (
    tester,
  ) async {
    final goalRepository = FakeGoalRepository(all: [buildTestGoal(id: 'goal-9')]);
    await tester.pumpWidget(
      _app(permissions: ['goals.manage'], goalRepository: goalRepository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Archive'));
    await tester.pumpAndSettle();

    expect(goalRepository.lastArchivedGoalId, 'goal-9');
    expect(goalRepository.lastActionWasManagerScoped, isFalse);
  });

  testWidgets(
    'Admin/HR can edit the achievement percentage; a Team Lead cannot',
    (tester) async {
      final goalRepository = FakeGoalRepository(
        all: [buildTestGoal(id: 'goal-9', achievementPercentage: 20)],
      );
      await tester.pumpWidget(
        _app(permissions: ['goals.manage'], goalRepository: goalRepository),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Achieved'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(goalRepository.lastUpdatedAchievementPercentage, 20);
    },
  );

  testWidgets("a Team Lead's edit dialog has no achievement percentage field", (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        role: 'Team Lead',
        goalRepository: FakeGoalRepository(
          team: [buildTestGoal(id: 'goal-9', employeeId: 'report-1')],
        ),
        employeeRepository: FakeEmployeeRepository(
          directReports: [buildTestEmployee(id: 'report-1')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Achieved'), findsNothing);
    expect(find.byType(Slider), findsNothing);
  });

  testWidgets('shows the employee photo/initials next to each goal', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        permissions: ['goals.manage'],
        goalRepository: FakeGoalRepository(
          all: [buildTestGoal(employeeName: 'Babar Hussain')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CircleAvatar), findsOneWidget);
  });

  testWidgets('searching by employee name filters the goals list', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        permissions: ['goals.manage'],
        goalRepository: FakeGoalRepository(
          all: [
            buildTestGoal(id: 'goal-1', employeeName: 'Babar Hussain'),
            buildTestGoal(id: 'goal-2', employeeName: 'Aamna Irfan'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Babar Hussain'), findsOneWidget);
    expect(find.text('Aamna Irfan'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Search by employee name'),
      'babar',
    );
    await tester.pumpAndSettle();

    expect(find.text('Babar Hussain'), findsOneWidget);
    expect(find.text('Aamna Irfan'), findsNothing);
  });

  testWidgets('filtering by department shows only that department\'s goals', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        permissions: ['goals.manage'],
        goalRepository: FakeGoalRepository(
          all: [
            buildTestGoal(
              id: 'goal-1',
              employeeName: 'Babar Hussain',
              departmentId: 'dept-seo',
            ),
            buildTestGoal(
              id: 'goal-2',
              employeeName: 'Aamna Irfan',
              departmentId: 'dept-marketing',
            ),
          ],
        ),
        employeeRepository: FakeEmployeeRepository(
          departments: [
            const Department(id: 'dept-seo', name: 'SEO'),
            const Department(id: 'dept-marketing', name: 'Marketing'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Babar Hussain'), findsOneWidget);
    expect(find.text('Aamna Irfan'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<String?>, 'Department'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('SEO').last);
    await tester.pumpAndSettle();

    expect(find.text('Babar Hussain'), findsOneWidget);
    expect(find.text('Aamna Irfan'), findsNothing);
  });
}
