import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/payroll/application/payroll_providers.dart';
import 'package:zera_erp/features/payroll/domain/entities/payroll_run_status.dart';
import 'package:zera_erp/features/payroll/presentation/pages/payroll_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_payroll.dart';

const _superAdmin = AuthUser(
  id: 'admin-1',
  email: 'admin@zeracreative.com',
  role: 'Super Admin',
  permissions: ['payroll.manage'],
);

Widget _app({FakePayrollRepository? repository, AuthUser? viewer}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(viewer ?? _superAdmin)),
      ),
      payrollRepositoryProvider.overrideWithValue(
        repository ?? FakePayrollRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: PayrollPage())),
  );
}

void main() {
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
    expect(find.text('Draft'), findsOneWidget);
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
}
