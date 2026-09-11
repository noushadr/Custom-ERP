import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/entities/payroll_summary.dart';
import 'package:zera_erp/features/freelancers/application/freelancers_providers.dart';
import 'package:zera_erp/features/payroll/application/payroll_providers.dart';
import 'package:zera_erp/features/payroll/data/models/payroll_run_summary_model.dart';
import 'package:zera_erp/features/payroll/domain/entities/payroll_run_status.dart';
import 'package:zera_erp/features/payroll/presentation/pages/payroll_page.dart';
import 'package:zera_erp/features/payroll/presentation/widgets/payroll_run_status_badge.dart';
import 'package:zera_erp/shared/widgets/metric_card.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_freelancers.dart';
import '../../helpers/fake_payroll.dart';

const _superAdmin = AuthUser(
  id: 'admin-1',
  email: 'admin@zeracreative.com',
  role: 'Super Admin',
  permissions: ['payroll.manage'],
);

Widget _app({
  FakePayrollRepository? repository,
  FakeFreelancersRepository? freelancersRepository,
  FakeEmployeeRepository? employeeRepository,
  AuthUser? viewer,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(viewer ?? _superAdmin)),
      ),
      payrollRepositoryProvider.overrideWithValue(
        repository ?? FakePayrollRepository(),
      ),
      freelancersRepositoryProvider.overrideWithValue(
        freelancersRepository ?? FakeFreelancersRepository(),
      ),
      employeeRepositoryProvider.overrideWithValue(
        employeeRepository ?? FakeEmployeeRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: PayrollPage())),
  );
}

void main() {
  testWidgets(
    'shows monthly, daily, and average payroll figures '
    '(moved here from the Dashboard)',
    (tester) async {
      await tester.pumpWidget(
        _app(
          employeeRepository: FakeEmployeeRepository(
            payrollSummary: const PayrollSummary(
              totalMonthlyPayroll: 250000,
              dailyPayroll: 8333.33,
              activeEmployeeCount: 4,
              departmentTotals: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Monthly Payroll'), findsOneWidget);
      expect(find.text('PKR 250,000'), findsOneWidget);
      expect(find.text('≈ \$899'), findsOneWidget);
      expect(find.text('Daily Payroll'), findsOneWidget);
      expect(find.text('PKR 8,333'), findsOneWidget);
      expect(find.text('≈ \$29'), findsOneWidget);
      expect(find.text('Average Salary'), findsOneWidget);
      expect(find.text('PKR 62,500'), findsOneWidget);
      expect(find.text('≈ \$224'), findsOneWidget);
    },
  );

  testWidgets(
    'shows departmental payroll totals (moved here from the Dashboard)',
    (tester) async {
      await tester.pumpWidget(
        _app(
          employeeRepository: FakeEmployeeRepository(
            payrollSummary: const PayrollSummary(
              totalMonthlyPayroll: 250000,
              dailyPayroll: 8333.33,
              activeEmployeeCount: 4,
              departmentTotals: [
                DepartmentPayrollTotal(
                  departmentId: 'dept-eng',
                  departmentName: 'Engineering',
                  totalMonthlyPayroll: 150000,
                  employeeCount: 2,
                ),
                DepartmentPayrollTotal(
                  departmentId: null,
                  departmentName: 'Unassigned',
                  totalMonthlyPayroll: 20000,
                  employeeCount: 1,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payroll by Department'), findsOneWidget);
      expect(find.text('Engineering'), findsOneWidget);
      expect(find.text('60.0% of payroll'), findsOneWidget);
      expect(find.text('PKR 150,000 · 2 employees'), findsOneWidget);
      expect(find.text('Unassigned'), findsOneWidget);
      expect(find.text('8.0% of payroll'), findsOneWidget);
      expect(find.text('PKR 20,000 · 1 employee'), findsOneWidget);
    },
  );

  testWidgets(
    'shows the Latest Payroll Run and Total Freelancers tiles '
    '(moved here from the Dashboard)',
    (tester) async {
      await tester.pumpWidget(
        _app(
          repository: FakePayrollRepository(
            runs: [
              buildTestPayrollRunSummary(
                month: 8,
                year: 2026,
                status: PayrollRunStatus.draft,
                totalNetPay: 600000,
              ),
            ],
          ),
          freelancersRepository: FakeFreelancersRepository(
            freelancers: [
              buildTestFreelancer(id: 'f1', isActive: true),
              buildTestFreelancer(id: 'f2', isActive: true),
              buildTestFreelancer(id: 'f3', isActive: false),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final latestRunCard = tester.widget<MetricCard>(
        find.byWidgetPredicate(
          (w) => w is MetricCard && w.label == 'Latest Payroll Run',
        ),
      );
      expect(latestRunCard.value, 'Draft');
      expect(latestRunCard.secondaryValue, 'PKR 600,000');
      // Only 2 of the 3 freelancers are active.
      final freelancersCard = tester.widget<MetricCard>(
        find.byWidgetPredicate(
          (w) => w is MetricCard && w.label == 'Total Freelancers',
        ),
      );
      expect(freelancersCard.value, '2');
    },
  );

  testWidgets(
    'the Latest Payroll Run card picks the most recent of several runs '
    'without throwing (regression: runs.reduce broke against the '
    "repository's concrete PayrollRunSummaryModel list)",
    (tester) async {
      PayrollRunSummaryModel run({
        required int year,
        required int month,
        required String status,
      }) => PayrollRunSummaryModel(
        id: '$year-$month',
        month: month,
        year: year,
        status: status,
        employeeCount: 1,
        totalNetPay: 1000,
        generatedByName: 'Noushad Ranani',
        finalizedByName: null,
        finalizedAt: null,
        paidByName: null,
        paidAt: null,
        createdAt: DateTime(year, month),
      );

      await tester.pumpWidget(
        _app(
          repository: FakePayrollRepository(
            runs: [
              run(year: 2026, month: 6, status: PayrollRunStatus.paid),
              run(year: 2026, month: 8, status: PayrollRunStatus.draft),
              run(year: 2026, month: 7, status: PayrollRunStatus.finalized),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final latestRunCard = tester.widget<MetricCard>(
        find.byWidgetPredicate(
          (w) => w is MetricCard && w.label == 'Latest Payroll Run',
        ),
      );
      expect(latestRunCard.value, 'Draft');
    },
  );

  testWidgets('lists payroll runs with period, status, and total net pay', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakePayrollRepository(
          runs: [
            buildTestPayrollRunSummary(
              month: 8,
              year: 2026,
              status: PayrollRunStatus.draft,
              employeeCount: 12,
              totalNetPay: 600000,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('August 2026'), findsOneWidget);
    // Scoped to the run row's own badge — the stats area above now also
    // shows "Draft" via the Latest Payroll Run tile.
    final statusBadge = tester.widget<PayrollRunStatusBadge>(
      find.byType(PayrollRunStatusBadge),
    );
    expect(statusBadge.status, PayrollRunStatus.draft);
    expect(find.text('12 employee(s)'), findsOneWidget);
    expect(find.text('PKR 600,000.00'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no runs yet', (
    tester,
  ) async {
    await tester.pumpWidget(_app(repository: FakePayrollRepository(runs: [])));
    await tester.pumpAndSettle();

    expect(find.text('No payroll runs generated yet.'), findsOneWidget);
  });

  testWidgets('generating a payroll run submits the selected month and year', (
    tester,
  ) async {
    final repository = FakePayrollRepository();
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Generate Payroll'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Generate'));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    expect(repository.lastGeneratedMonth, now.month);
    expect(repository.lastGeneratedYear, now.year);
  });

  testWidgets('tapping a run opens its detail page', (tester) async {
    await tester.pumpWidget(
      _app(
        repository: FakePayrollRepository(
          runs: [buildTestPayrollRunSummary(month: 8, year: 2026)],
          runDetail: buildTestPayrollRunDetail(month: 8, year: 2026),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('August 2026'));
    await tester.pumpAndSettle();

    expect(find.text('Payroll Run'), findsOneWidget); // the detail AppBar
  });

  testWidgets(
    'shows an access-denied message and never fetches payroll runs for a '
    'viewer without payroll.manage — a frontend-side second line of '
    "defense, since this app's IndexedStack-based nav keeps every page "
    'mounted regardless of which tab is visible',
    (tester) async {
      final repository = FakePayrollRepository(
        runs: [buildTestPayrollRunSummary()],
      );

      await tester.pumpWidget(
        _app(
          repository: repository,
          viewer: const AuthUser(
            id: 'employee-1',
            email: 'employee@zeracreative.com',
            role: 'Employee',
            permissions: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text("You don't have permission to view this page."),
        findsOneWidget,
      );
      expect(find.text('August 2026'), findsNothing);
      expect(repository.getRunsCallCount, 0);
    },
  );

  testWidgets(
    'the Freelancers tab lists freelancers with their role and active status',
    (tester) async {
      await tester.pumpWidget(
        _app(
          freelancersRepository: FakeFreelancersRepository(
            freelancers: [
              buildTestFreelancer(
                fullName: 'Kulsum Zehra',
                role: 'Content Writer',
              ),
              buildTestFreelancer(
                id: 'freelancer-2',
                fullName: 'Hamza Saqib',
                role: 'Data Entry',
                isActive: false,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Freelancers'));
      await tester.pumpAndSettle();

      expect(find.text('Kulsum Zehra'), findsOneWidget);
      expect(find.text('Content Writer'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Hamza Saqib'), findsOneWidget);
      expect(find.text('Data Entry'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
    },
  );

  testWidgets('adding a freelancer submits the entered name and role', (
    tester,
  ) async {
    final freelancersRepository = FakeFreelancersRepository(freelancers: []);
    await tester.pumpWidget(
      _app(freelancersRepository: freelancersRepository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Freelancers'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Add Freelancer'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Full name'),
      'Kulsum Zehra',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Role (optional)'),
      'Content Writer',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(freelancersRepository.lastCreatedFullName, 'Kulsum Zehra');
    expect(freelancersRepository.lastCreatedRole, 'Content Writer');
  });

  testWidgets(
    'tapping a freelancer and toggling Active submits the update',
    (tester) async {
      final freelancersRepository = FakeFreelancersRepository(
        freelancers: [buildTestFreelancer(fullName: 'Kulsum Zehra')],
      );
      await tester.pumpWidget(
        _app(freelancersRepository: freelancersRepository),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Freelancers'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kulsum Zehra'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SwitchListTile));
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(freelancersRepository.lastUpdatedId, 'freelancer-1');
      expect(freelancersRepository.lastUpdatedIsActive, false);
    },
  );
}
