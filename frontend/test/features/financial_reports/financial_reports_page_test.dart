import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/financial_reports/application/financial_reports_providers.dart';
import 'package:zera_erp/features/financial_reports/presentation/pages/financial_reports_page.dart';
import 'package:zera_erp/shared/widgets/metric_card.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_financial_reports.dart';

const _superAdmin = AuthUser(
  id: 'admin-1',
  email: 'admin@zeracreative.com',
  role: 'Super Admin',
  permissions: ['finances.manage'],
);

Widget _app({FakeFinancialReportsRepository? repository, AuthUser? viewer}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(viewer ?? _superAdmin)),
      ),
      financialReportsRepositoryProvider.overrideWithValue(
        repository ?? FakeFinancialReportsRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: FinancialReportsPage())),
  );
}

Finder _periodSegment(String label) => find.descendant(
  of: find.byType(SegmentedButton<int?>),
  matching: find.text(label),
);

void main() {
  testWidgets('shows an empty state when there are no records', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('No financial records yet.'), findsOneWidget);
  });

  testWidgets(
    'does not repeat a "Financial Reports" heading — the top bar already '
    'shows it',
    (tester) async {
      await tester.pumpWidget(
        _app(repository: FakeFinancialReportsRepository(records: [buildTestFinancialRecord()])),
      );
      await tester.pumpAndSettle();

      expect(find.text('Financial Reports'), findsNothing);
    },
  );

  testWidgets('has no PKR/USD toggle — every money figure always shows both', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(repository: FakeFinancialReportsRepository(records: [buildTestFinancialRecord()])),
    );
    await tester.pumpAndSettle();

    expect(find.text('PKR'), findsNothing);
    expect(find.text('USD'), findsNothing);
    // Exactly one SegmentedButton remains — the Period selector.
    expect(find.byType(SegmentedButton<int?>), findsOneWidget);
  });

  testWidgets(
    'defaults to All-Time — totals span every year, with the covered date '
    'range, and monthly detail stays hidden until a year is picked',
    (tester) async {
      await tester.pumpWidget(
        _app(
          repository: FakeFinancialReportsRepository(
            records: [
              buildTestFinancialRecord(
                id: 'r1',
                year: 2022,
                month: 7,
                revenueRs: 1000000,
                revenueUsd: 3571,
                expenseRs: 600000,
                expenseUsd: 2143,
              ),
              buildTestFinancialRecord(
                id: 'r2',
                year: 2026,
                month: 1,
                revenueRs: 2000000,
                revenueUsd: 7142,
                expenseRs: 1200000,
                expenseUsd: 4286,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_periodSegment('All-Time'), findsOneWidget);
      expect(find.text('Totals (All-Time)'), findsOneWidget);
      expect(find.text('Since Jul 2022 – Jan 2026 · 2 months of data'), findsOneWidget);

      final cardValues = {
        for (final card in tester.widgetList<MetricCard>(find.byType(MetricCard)))
          card.label: card.value,
      };
      // The tile labels themselves stay plain ("Total Revenue", not "Total
      // Revenue (All-Time)") — the "Totals (All-Time)" heading above them
      // already states the scope.
      expect(cardValues['Total Revenue'], 'Rs3,000,000 (\$10,713)');
      expect(cardValues['Total Expense'], 'Rs1,800,000 (\$6,429)');
      expect(cardValues['Total Profit'], 'Rs1,200,000 (\$4,284)');

      // Monthly detail (charts + table) is inherently single-year — hidden
      // by default, with a hint explaining why.
      expect(find.byType(DataTable), findsNothing);
      expect(
        find.textContaining('Select a year above to see its monthly'),
        findsOneWidget,
      );
      // The multi-year comparison chart is not "monthly detail" — it stays.
      expect(find.text('Revenue vs Expense vs Profit by Year'), findsOneWidget);
    },
  );

  testWidgets(
    'picking a year narrows the totals and reveals monthly detail; '
    'switching back to All-Time hides it again',
    (tester) async {
      await tester.pumpWidget(
        _app(
          repository: FakeFinancialReportsRepository(
            records: [
              buildTestFinancialRecord(
                id: 'r1',
                year: 2025,
                month: 1,
                revenueRs: 500000,
                revenueUsd: 1786,
                expenseRs: 400000,
                expenseUsd: 1429,
              ),
              buildTestFinancialRecord(
                id: 'r2',
                year: 2026,
                month: 1,
                revenueRs: 2000000,
                revenueUsd: 7142,
                expenseRs: 1200000,
                expenseUsd: 4286,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(_periodSegment('2025'));
      await tester.pumpAndSettle();

      final cardValues = {
        for (final card in tester.widgetList<MetricCard>(find.byType(MetricCard)))
          card.label: card.value,
      };
      expect(cardValues['Total Revenue'], 'Rs500,000 (\$1,786)');
      // The heading switches to the selected year, not "All-Time".
      expect(find.text('Totals (2025)'), findsOneWidget);
      expect(find.text('Totals (All-Time)'), findsNothing);
      expect(find.byType(DataTable), findsOneWidget);
      expect(
        find.textContaining('Select a year above to see its monthly'),
        findsNothing,
      );

      await tester.tap(_periodSegment('All-Time'));
      await tester.pumpAndSettle();

      expect(find.byType(DataTable), findsNothing);
      expect(
        find.textContaining('Select a year above to see its monthly'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'the monthly charts label each bar with a plain month — the chart '
    'title already names the year, since these charts are always scoped '
    'to one selected year',
    (tester) async {
      await tester.pumpWidget(
        _app(
          repository: FakeFinancialReportsRepository(
            records: [
              buildTestFinancialRecord(id: 'r1', year: 2026, month: 3),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(_periodSegment('2026'));
      await tester.pumpAndSettle();

      expect(find.text('Mar'), findsWidgets);
      expect(find.text('Mar\n26'), findsNothing);
      expect(find.text('Revenue vs Expense — 2026'), findsOneWidget);
      expect(find.text('Monthly Profit / Loss — 2026'), findsOneWidget);
    },
  );

  testWidgets(
    'the yearly comparison chart offers Revenue, Expense, and Profit',
    (tester) async {
      await tester.pumpWidget(
        _app(
          repository: FakeFinancialReportsRepository(
            records: [buildTestFinancialRecord()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Revenue vs Expense vs Profit by Year'), findsOneWidget);
    },
  );

  testWidgets('the monthly detail table shows each record once a year is picked', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakeFinancialReportsRepository(
          records: [
            buildTestFinancialRecord(
              id: 'r1',
              year: 2026,
              month: 3,
              revenueRs: 741000,
              revenueUsd: 2647,
              expenseRs: 489984,
              expenseUsd: 1750,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(_periodSegment('2026'));
    await tester.pumpAndSettle();

    // "Mar 2026" also appears on the Best/Worst Month tiles above the
    // table, since this record is the only one in the year — scope to the
    // table specifically.
    expect(
      find.descendant(of: find.byType(DataTable), matching: find.text('Mar 2026')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(DataTable),
        matching: find.text('Rs741,000 (\$2,647)'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows an access-denied message instead of any financial data for a '
    'viewer without finances.manage',
    (tester) async {
      final repository = FakeFinancialReportsRepository(
        records: [buildTestFinancialRecord()],
      );

      await tester.pumpWidget(
        _app(
          repository: repository,
          viewer: const AuthUser(
            id: 'hr-1',
            email: 'hr@zeracreative.com',
            role: 'HR/Manager',
            permissions: ['payroll.manage'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text("You don't have permission to view this page."),
        findsOneWidget,
      );
      expect(find.byType(MetricCard), findsNothing);
      expect(repository.getRecordsCallCount, 0);
    },
  );
}
