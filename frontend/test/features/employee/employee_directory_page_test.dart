import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/presentation/pages/employee_directory_page.dart';
import 'package:zera_erp/features/employee/presentation/widgets/employee_status_badges.dart';
import 'package:zera_erp/features/performance_reviews/application/performance_review_providers.dart';
import 'package:zera_erp/shared/models/named_ref.dart';
import 'package:zera_erp/shared/utils/date_format.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_performance_review.dart';

Widget _app({
  required List<String> permissions,
  required FakeEmployeeRepository repository,
  FakePerformanceReviewRepository? performanceReviewRepository,
}) {
  final user = AuthUser(
    id: 'user-1',
    email: 'jane.doe@zeracreative.com',
    role: 'HR/Manager',
    permissions: permissions,
  );

  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(user)),
      ),
      employeeRepositoryProvider.overrideWithValue(repository),
      performanceReviewRepositoryProvider.overrideWithValue(
        performanceReviewRepository ?? FakePerformanceReviewRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: EmployeeDirectoryPage())),
  );
}

/// An ISO 'YYYY-MM-DD' exactly [years] years (and, optionally, [months])
/// before today — so tenure assertions stay correct no matter when the test
/// suite actually runs.
String _joinedAgo(int years, {int months = 0}) {
  final now = DateTime.now();
  var year = now.year - years;
  var month = now.month - months;
  if (month < 1) {
    year -= 1;
    month += 12;
  }
  final date = DateTime(year, month, now.day);
  return date.toIso8601String().substring(0, 10);
}

void main() {
  testWidgets('shows the employee list and invite button with full access', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(
      employees: [buildTestEmployee()],
    );

    await tester.pumpWidget(
      _app(
        permissions: ['employees.read', 'employees.manage'],
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Invite Employee'), findsOneWidget);
  });

  testWidgets('hides the invite button without employees.manage', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(
      employees: [buildTestEmployee()],
    );

    await tester.pumpWidget(
      _app(permissions: ['employees.read'], repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Invite Employee'), findsNothing);
  });

  testWidgets('hierarchy view nests reports under their manager', (
    tester,
  ) async {
    final manager = buildTestEmployee(
      id: 'manager-1',
      fullName: 'Mona Manager',
      designation: 'Engineering Lead',
    );
    final report = buildTestEmployee(
      id: 'report-1',
      fullName: 'Ravi Report',
      designation: 'Software Engineer',
      reportingManager: const NamedRef(id: 'manager-1', name: 'Mona Manager'),
    );
    final repository = FakeEmployeeRepository(employees: [manager, report]);

    await tester.pumpWidget(
      _app(permissions: ['employees.read'], repository: repository),
    );
    await tester.pumpAndSettle();

    // Default view is the flat list.
    expect(find.text('Mona Manager'), findsOneWidget);
    expect(find.text('Ravi Report'), findsOneWidget);

    await tester.tap(find.text('Hierarchy'));
    await tester.pumpAndSettle();

    // Nodes start collapsed until the user opens them.
    expect(find.text('Mona Manager'), findsOneWidget);
    expect(find.text('Ravi Report'), findsNothing);
    expect(find.textContaining('1 person'), findsOneWidget);

    await tester.tap(find.textContaining('1 person'));
    await tester.pumpAndSettle();

    // The report is nested under the manager, not shown as a root.
    expect(find.text('Mona Manager'), findsOneWidget);
    expect(find.text('Ravi Report'), findsOneWidget);
  });

  testWidgets('filters the list by search query', (tester) async {
    final jane = buildTestEmployee(id: 'employee-1', fullName: 'Jane Doe');
    final ravi = buildTestEmployee(
      id: 'employee-2',
      fullName: 'Ravi Report',
      email: 'ravi.report@zeracreative.com',
      designation: 'Software Engineer',
    );
    final repository = FakeEmployeeRepository(employees: [jane, ravi]);

    await tester.pumpWidget(
      _app(permissions: ['employees.read'], repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Ravi Report'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ravi');
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsNothing);
    expect(find.text('Ravi Report'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nobody matches this');
    await tester.pumpAndSettle();

    expect(find.text('No employees match your search.'), findsOneWidget);
  });

  testWidgets('shows each employee\'s department and reporting manager', (
    tester,
  ) async {
    final withBoth = buildTestEmployee(
      id: 'employee-1',
      fullName: 'Jane Doe',
      department: const NamedRef(id: 'dept-eng', name: 'Engineering'),
      reportingManager: const NamedRef(id: 'employee-2', name: 'Mona Manager'),
    );
    final withNeither = buildTestEmployee(
      id: 'employee-2',
      fullName: 'Mona Manager',
      email: 'mona.manager@zeracreative.com',
    );
    final repository = FakeEmployeeRepository(
      employees: [withBoth, withNeither],
    );

    await tester.pumpWidget(
      _app(permissions: ['employees.read'], repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Department: Engineering'), findsOneWidget);
    expect(find.text('Mona Manager'), findsOneWidget);
    expect(find.text('Reports to: Mona Manager'), findsOneWidget);
    expect(find.text('Department: None'), findsOneWidget);
    expect(find.text('Reports to: —'), findsOneWidget);
  });

  testWidgets('shows a restricted message without employees.read', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(
      employees: [buildTestEmployee()],
    );

    await tester.pumpWidget(_app(permissions: [], repository: repository));
    await tester.pumpAndSettle();

    expect(
      find.text("You don't have access to the full directory."),
      findsOneWidget,
    );
    expect(find.text('View my profile'), findsOneWidget);
  });

  testWidgets(
    'hides resigned and terminated employees from the hierarchy view',
    (tester) async {
      final active = buildTestEmployee(
        id: 'employee-1',
        fullName: 'Active Person',
      );
      final resigned = buildTestEmployee(
        id: 'employee-2',
        fullName: 'Resigned Person',
        email: 'resigned.person@zeracreative.com',
        employmentStatus: 'resigned',
      );
      final terminated = buildTestEmployee(
        id: 'employee-3',
        fullName: 'Terminated Person',
        email: 'terminated.person@zeracreative.com',
        employmentStatus: 'terminated',
      );
      final repository = FakeEmployeeRepository(
        employees: [active, resigned, terminated],
      );

      await tester.pumpWidget(
        _app(permissions: ['employees.read'], repository: repository),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hierarchy'));
      await tester.pumpAndSettle();

      expect(find.text('Active Person'), findsOneWidget);
      expect(find.text('Resigned Person'), findsNothing);
      expect(find.text('Terminated Person'), findsNothing);
    },
  );

  testWidgets(
    "a still-active report becomes a root when their manager has left",
    (tester) async {
      final formerManager = buildTestEmployee(
        id: 'manager-1',
        fullName: 'Former Manager',
        email: 'former.manager@zeracreative.com',
        employmentStatus: 'resigned',
      );
      final report = buildTestEmployee(
        id: 'report-1',
        fullName: 'Still Active',
        reportingManager: const NamedRef(
          id: 'manager-1',
          name: 'Former Manager',
        ),
      );
      final repository = FakeEmployeeRepository(
        employees: [formerManager, report],
      );

      await tester.pumpWidget(
        _app(permissions: ['employees.read'], repository: repository),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hierarchy'));
      await tester.pumpAndSettle();

      // Shown directly as a root — not nested under (or hidden because of)
      // the departed manager, and no toggle to expand into since they have
      // no visible reports of their own.
      expect(find.text('Still Active'), findsOneWidget);
      expect(find.text('Former Manager'), findsNothing);
      expect(find.textContaining('person'), findsNothing);
    },
  );

  testWidgets(
    'only counts active employees in the work-mode summary',
    (tester) async {
      final repository = FakeEmployeeRepository(
        employees: [
          buildTestEmployee(
            id: 'employee-1',
            employmentStatus: 'active',
            workMode: 'remote',
          ),
          buildTestEmployee(
            id: 'employee-2',
            employmentStatus: 'resigned',
            workMode: 'remote',
          ),
          buildTestEmployee(
            id: 'employee-3',
            employmentStatus: 'terminated',
            workMode: 'hybrid',
          ),
        ],
      );

      await tester.pumpWidget(
        _app(permissions: ['employees.read'], repository: repository),
      );
      await tester.pumpAndSettle();

      // Only employee-1 is active, so Remote should read 1 (not 2), and
      // Hybrid should read 0 since its only member has left.
      expect(find.text('On-site: 0'), findsOneWidget);
      expect(find.text('Remote: 1'), findsOneWidget);
      expect(find.text('Hybrid: 0'), findsOneWidget);
    },
  );

  testWidgets(
    'renders employment status and work mode badges in the dense size',
    (tester) async {
      final repository = FakeEmployeeRepository(
        employees: [buildTestEmployee()],
      );

      await tester.pumpWidget(
        _app(permissions: ['employees.read'], repository: repository),
      );
      await tester.pumpAndSettle();

      final badge = tester.widget<EmploymentStatusBadge>(
        find.byType(EmploymentStatusBadge),
      );
      final workModeBadge = tester.widget<WorkModeBadge>(
        find.byType(WorkModeBadge),
      );
      expect(badge.dense, isTrue);
      expect(workModeBadge.dense, isTrue);
    },
  );

  testWidgets('shows each employee\'s tenure since joining', (tester) async {
    final repository = FakeEmployeeRepository(
      employees: [
        buildTestEmployee(joiningDate: _joinedAgo(2)),
      ],
    );

    await tester.pumpWidget(
      _app(permissions: ['employees.read'], repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 yrs'), findsOneWidget);
  });

  testWidgets(
    'hides the last-review chip without performance.manage',
    (tester) async {
      final repository = FakeEmployeeRepository(
        employees: [buildTestEmployee()],
      );

      await tester.pumpWidget(
        _app(permissions: ['employees.read'], repository: repository),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Last Review'), findsNothing);
      expect(find.textContaining('No review yet'), findsNothing);
    },
  );

  testWidgets(
    'shows a pending last-review status for a performance.manage holder',
    (tester) async {
      final repository = FakeEmployeeRepository(
        employees: [buildTestEmployee(id: 'employee-1')],
      );
      final reviewRepository = FakePerformanceReviewRepository(
        latestReviewSummaries: [
          buildTestPerformanceReviewSummary(
            employeeId: 'employee-1',
            status: 'pending',
          ),
        ],
      );

      await tester.pumpWidget(
        _app(
          permissions: ['employees.read', 'performance.manage'],
          repository: repository,
          performanceReviewRepository: reviewRepository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Last Review: Pending'), findsOneWidget);
    },
  );

  testWidgets(
    'shows the finalized date for a completed last review',
    (tester) async {
      final repository = FakeEmployeeRepository(
        employees: [buildTestEmployee(id: 'employee-1')],
      );
      final finalizedAt = DateTime.utc(2026, 2, 1, 12);
      final reviewRepository = FakePerformanceReviewRepository(
        latestReviewSummaries: [
          buildTestPerformanceReviewSummary(
            employeeId: 'employee-1',
            status: 'finalized',
            finalizedAt: finalizedAt,
          ),
        ],
      );

      await tester.pumpWidget(
        _app(
          permissions: ['employees.read', 'performance.manage'],
          repository: repository,
          performanceReviewRepository: reviewRepository,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Last Review: ${formatDisplayDateOnly(finalizedAt)}'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows "No review yet" for an employee with no reviews at all',
    (tester) async {
      final repository = FakeEmployeeRepository(
        employees: [buildTestEmployee(id: 'employee-1')],
      );
      final reviewRepository = FakePerformanceReviewRepository(
        latestReviewSummaries: const [],
      );

      await tester.pumpWidget(
        _app(
          permissions: ['employees.read', 'performance.manage'],
          repository: repository,
          performanceReviewRepository: reviewRepository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No review yet'), findsOneWidget);
    },
  );
}
