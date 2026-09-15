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
import 'package:zera_erp/shared/widgets/metric_card.dart';
import 'package:zera_erp/shared/widgets/pie_chart_panel.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_performance_review.dart';

List<Override> _overridesFor({
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

  return [
    authControllerProvider.overrideWith(
      (ref) => PresetAuthController(AuthAuthenticated(user)),
    ),
    employeeRepositoryProvider.overrideWithValue(repository),
    performanceReviewRepositoryProvider.overrideWithValue(
      performanceReviewRepository ?? FakePerformanceReviewRepository(),
    ),
  ];
}

Widget _app({
  required List<String> permissions,
  required FakeEmployeeRepository repository,
  FakePerformanceReviewRepository? performanceReviewRepository,
}) {
  return ProviderScope(
    overrides: _overridesFor(
      permissions: permissions,
      repository: repository,
      performanceReviewRepository: performanceReviewRepository,
    ),
    child: const MaterialApp(home: Scaffold(body: EmployeeDirectoryPage())),
  );
}

/// Widens the default 800x600 test surface — this page's header (Work Mode
/// stats + status filter/search row) leaves too little room for the
/// hierarchy tree below at the default height, same fix as leave_page_test's
/// own `_useTallSurface`.
Future<void> _useTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
  testWidgets('shows the employee list and add-employee button with full access', (
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
    expect(find.text('Add Employee'), findsOneWidget);
  });

  testWidgets('hides the add-employee button without employees.manage', (
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
    expect(find.text('Add Employee'), findsNothing);
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

    await _useTallSurface(tester);
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

  testWidgets(
    "shows an employee's employment type and probation status on their card",
    (tester) async {
      final onProbation = buildTestEmployee(
        id: 'employee-1',
        fullName: 'Part Timer',
        employmentType: 'part_time',
        probationEndDate: '2026-06-01',
        probationStatus: 'on_probation',
      );
      final pastProbation = buildTestEmployee(
        id: 'employee-2',
        fullName: 'Full Timer',
        email: 'full.timer@zeracreative.com',
        employmentType: 'full_time',
        probationEndDate: '2025-01-01',
        probationStatus: 'completed',
      );
      final noProbationOnFile = buildTestEmployee(
        id: 'employee-3',
        fullName: 'No Probation',
        email: 'no.probation@zeracreative.com',
      );
      final repository = FakeEmployeeRepository(
        employees: [onProbation, pastProbation, noProbationOnFile],
      );

      await tester.pumpWidget(
        _app(permissions: ['employees.read'], repository: repository),
      );
      await tester.pumpAndSettle();

      expect(find.text('Part-time'), findsOneWidget);
      // 'On Probation' also appears as the stats section's own tile label
      // now, so scope to the badge specifically rather than asserting
      // page-wide uniqueness.
      expect(
        find.descendant(
          of: find.byType(ProbationBadge),
          matching: find.text('On Probation'),
        ),
        findsOneWidget,
      );
      // "Full-time" appears for both Full Timer and No Probation (the
      // default employmentType) — assert at least one, not uniqueness.
      expect(find.text('Full-time'), findsWidgets);
      expect(find.text('Probation Complete'), findsOneWidget);
    },
  );

  testWidgets('shows each employee\'s department and reporting manager', (
    tester,
  ) async {
    await _useTallSurface(tester);
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
    'only counts active employees in the combined work-mode tile',
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

      // Only employee-1 is active, so the combined On-site/Remote/Hybrid
      // tile should read 0/1/0 — On-site and Hybrid's only members are gone
      // (resigned/terminated), and Remote counts just the one active member.
      // Scoped to the tile itself since other stat tiles on this page (e.g.
      // Notice Period, On Leave) also happen to read '0' for this dataset.
      final workModeCard = find.byKey(const Key('work-mode-card'));
      expect(workModeCard, findsOneWidget);
      expect(
        find.descendant(of: workModeCard, matching: find.text('0')),
        findsNWidgets(2),
      );
      expect(
        find.descendant(of: workModeCard, matching: find.text('1')),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows Notice Period, On Leave, and On Probation stat counts', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(
      employees: [
        buildTestEmployee(id: 'employee-1', employmentStatus: 'notice_period'),
        buildTestEmployee(
          id: 'employee-2',
          email: 'employee-2@zeracreative.com',
          employmentStatus: 'notice_period',
        ),
        buildTestEmployee(
          id: 'employee-3',
          email: 'employee-3@zeracreative.com',
          employmentStatus: 'on_leave',
        ),
        buildTestEmployee(
          id: 'employee-4',
          email: 'employee-4@zeracreative.com',
          probationStatus: 'on_probation',
          probationEndDate: '2026-12-01',
        ),
      ],
    );

    await tester.pumpWidget(
      _app(permissions: ['employees.read'], repository: repository),
    );
    await tester.pumpAndSettle();

    final noticePeriodCard = tester.widget<MetricCard>(
      find.byWidgetPredicate(
        (w) => w is MetricCard && w.label == 'Notice Period',
      ),
    );
    final onLeaveCard = tester.widget<MetricCard>(
      find.byWidgetPredicate((w) => w is MetricCard && w.label == 'On Leave'),
    );
    final onProbationCard = tester.widget<MetricCard>(
      find.byWidgetPredicate(
        (w) => w is MetricCard && w.label == 'On Probation',
      ),
    );
    expect(noticePeriodCard.value, '2');
    expect(onLeaveCard.value, '1');
    expect(onProbationCard.value, '1');
  });

  testWidgets(
    'shows the Avg. Profile Completion stat, moved here from the Dashboard',
    (tester) async {
      final repository = FakeEmployeeRepository(
        employees: [
          buildTestEmployee(id: 'employee-1', profileCompletionPercentage: 40),
          buildTestEmployee(
            id: 'employee-2',
            email: 'employee-2@zeracreative.com',
            profileCompletionPercentage: 60,
          ),
        ],
      );

      await tester.pumpWidget(
        _app(permissions: ['employees.read'], repository: repository),
      );
      await tester.pumpAndSettle();

      final avgCard = tester.widget<MetricCard>(
        find.byWidgetPredicate(
          (w) => w is MetricCard && w.label == 'Avg. Profile Completion',
        ),
      );
      expect(avgCard.value, '50%');
    },
  );

  testWidgets(
    'shows the Pending Performance Reviews count and weekly delta for a '
    'performance.manage holder, moved here from the Dashboard',
    (tester) async {
      await tester.pumpWidget(
        _app(
          permissions: ['employees.read', 'performance.manage'],
          repository: FakeEmployeeRepository(employees: [buildTestEmployee()]),
          performanceReviewRepository: FakePerformanceReviewRepository(
            allPendingReviews: [
              buildTestPerformanceReview(id: 'review-1'),
              buildTestPerformanceReview(id: 'review-2'),
            ],
            pendingReviewsDelta: -1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pendingCard = tester.widget<MetricCard>(
        find.byWidgetPredicate(
          (w) => w is MetricCard && w.label == 'Pending Performance Reviews',
        ),
      );
      expect(pendingCard.value, '2');
      expect(pendingCard.secondaryValue, '-1 in last 7 days');
    },
  );

  testWidgets(
    'hides Pending Performance Reviews without performance.manage',
    (tester) async {
      await tester.pumpWidget(
        _app(
          permissions: ['employees.read'],
          repository: FakeEmployeeRepository(employees: [buildTestEmployee()]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending Performance Reviews'), findsNothing);
    },
  );

  testWidgets(
    'shows an Employees by Department breakdown, counting only active '
    'employees',
    (tester) async {
      await _useTallSurface(tester);
      final repository = FakeEmployeeRepository(
        employees: [
          buildTestEmployee(
            id: 'employee-1',
            department: const NamedRef(id: 'dept-seo', name: 'SEO'),
          ),
          buildTestEmployee(
            id: 'employee-2',
            email: 'employee-2@zeracreative.com',
            department: const NamedRef(id: 'dept-seo', name: 'SEO'),
          ),
          // A third active employee in a different department, so the
          // donut's own center total (3) doesn't coincidentally match SEO's
          // legend count (2) below.
          buildTestEmployee(
            id: 'employee-3',
            email: 'employee-3@zeracreative.com',
            department: const NamedRef(id: 'dept-sales', name: 'Sales'),
          ),
          buildTestEmployee(
            id: 'employee-4',
            email: 'employee-4@zeracreative.com',
            department: const NamedRef(id: 'dept-hr', name: 'HR'),
            employmentStatus: 'resigned',
          ),
        ],
      );

      await tester.pumpWidget(
        _app(permissions: ['employees.read'], repository: repository),
      );
      await tester.pumpAndSettle();

      expect(find.text('Employees by Department'), findsOneWidget);
      expect(find.text('SEO'), findsOneWidget);
      // Scoped to the breakdown panel itself — '2' also happens to be the
      // Total Employees and Work Mode "On-site" tiles' value for this
      // dataset (all three active employees default to on-site).
      final panel = find.byType(PieChartPanel);
      expect(
        find.descendant(of: panel, matching: find.text('2')),
        findsOneWidget,
      );
      // employee-4 is resigned, so HR shouldn't appear in the breakdown at
      // all.
      expect(find.text('HR'), findsNothing);
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

  testWidgets(
    "shows the Total Employees tile's active count and 30-day delta "
    '(moved here from the Dashboard)',
    (tester) async {
      final repository = FakeEmployeeRepository(
        employees: [
          buildTestEmployee(id: 'employee-1', employmentStatus: 'active'),
          buildTestEmployee(id: 'employee-2', employmentStatus: 'resigned'),
        ],
        activeEmployeeDelta: 1,
      );

      await tester.pumpWidget(
        _app(permissions: ['employees.read'], repository: repository),
      );
      await tester.pumpAndSettle();

      final totalCard = tester.widget<MetricCard>(
        find.byWidgetPredicate(
          (w) => w is MetricCard && w.label == 'Total Employees',
        ),
      );
      // Only employee-1 is active, so the tile reads 1 (not the full
      // headcount of 2).
      expect(totalCard.value, '1');
      expect(totalCard.secondaryValue, '+1 in last 30 days');
    },
  );

  testWidgets(
    "shows a negative Total Employees tile delta as e.g. '-1 in last 30 "
    "days'",
    (tester) async {
      final repository = FakeEmployeeRepository(
        employees: [buildTestEmployee(employmentStatus: 'resigned')],
        activeEmployeeDelta: -1,
      );

      await tester.pumpWidget(
        _app(permissions: ['employees.read'], repository: repository),
      );
      await tester.pumpAndSettle();

      final totalCard = tester.widget<MetricCard>(
        find.byWidgetPredicate(
          (w) => w is MetricCard && w.label == 'Total Employees',
        ),
      );
      expect(totalCard.secondaryValue, '-1 in last 30 days');
    },
  );

  testWidgets(
    "shows 'No change in last 30 days' for a zero Total Employees tile "
    'delta',
    (tester) async {
      final repository = FakeEmployeeRepository(activeEmployeeDelta: 0);

      await tester.pumpWidget(
        _app(permissions: ['employees.read'], repository: repository),
      );
      await tester.pumpAndSettle();

      final totalCard = tester.widget<MetricCard>(
        find.byWidgetPredicate(
          (w) => w is MetricCard && w.label == 'Total Employees',
        ),
      );
      expect(totalCard.secondaryValue, 'No change in last 30 days');
    },
  );

  testWidgets(
    'a status filter dropdown narrows the list to one employment status',
    (tester) async {
      final active = buildTestEmployee(
        id: 'employee-1',
        fullName: 'Active Person',
      );
      final onNotice = buildTestEmployee(
        id: 'employee-2',
        fullName: 'Notice Person',
        email: 'notice.person@zeracreative.com',
        employmentStatus: 'notice_period',
      );
      final repository = FakeEmployeeRepository(
        employees: [active, onNotice],
      );

      await tester.pumpWidget(
        _app(permissions: ['employees.read'], repository: repository),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active Person'), findsOneWidget);
      expect(find.text('Notice Person'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(
          DropdownButtonFormField<String?>,
          'All statuses',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notice Period').last);
      await tester.pumpAndSettle();

      expect(find.text('Active Person'), findsNothing);
      expect(find.text('Notice Person'), findsOneWidget);
    },
  );

  testWidgets(
    "the status filter's 'On Probation' option filters by "
    "probationStatus, not employmentStatus — a probationary employee's "
    "employmentStatus stays 'active' so they still show up in payroll etc.",
    (tester) async {
      final onProbation = buildTestEmployee(
        id: 'employee-1',
        fullName: 'Probation Person',
        probationEndDate: '2026-12-01',
        probationStatus: 'on_probation',
      );
      final activeNotOnProbation = buildTestEmployee(
        id: 'employee-2',
        fullName: 'Confirmed Person',
        email: 'confirmed.person@zeracreative.com',
      );
      final repository = FakeEmployeeRepository(
        employees: [onProbation, activeNotOnProbation],
      );

      await tester.pumpWidget(
        _app(permissions: ['employees.read'], repository: repository),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(
          DropdownButtonFormField<String?>,
          'All statuses',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('On Probation').last);
      await tester.pumpAndSettle();

      expect(find.text('Probation Person'), findsOneWidget);
      expect(find.text('Confirmed Person'), findsNothing);
    },
  );

  testWidgets(
    'picks up a Notice Period pre-filter set on employeeStatusFilterProvider '
    'after this page is already mounted (the real app never rebuilds this '
    "page's initState for a later Dashboard tap — see main.dart's "
    'IndexedStack-based nav)',
    (tester) async {
      final active = buildTestEmployee(
        id: 'employee-1',
        fullName: 'Active Person',
      );
      final onNotice = buildTestEmployee(
        id: 'employee-2',
        fullName: 'Notice Person',
        email: 'notice.person@zeracreative.com',
        employmentStatus: 'notice_period',
      );
      final repository = FakeEmployeeRepository(
        employees: [active, onNotice],
      );
      final container = ProviderContainer(
        overrides: _overridesFor(
          permissions: ['employees.read'],
          repository: repository,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: EmployeeDirectoryPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active Person'), findsOneWidget);
      expect(find.text('Notice Person'), findsOneWidget);

      // Exactly what the Dashboard's Notice Period tile does — set the
      // provider well after this page was first built.
      container.read(employeeStatusFilterProvider.notifier).state =
          'notice_period';
      await tester.pumpAndSettle();

      expect(find.text('Active Person'), findsNothing);
      expect(find.text('Notice Person'), findsOneWidget);
    },
  );
}
