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
    // Exactly one SegmentedButton remains — the year selector.
    expect(find.byType(SegmentedButton<int>), findsOneWidget);
  });

  testWidgets('shows summary stat tiles for the most recent year', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakeFinancialReportsRepository(
          records: [
            buildTestFinancialRecord(
              id: 'r1',
              year: 2025,
              month: 1,
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

    // Defaults to the most recent year (2026), not 2025. Every PKR figure
    // is the full precise number, with its USD equivalent in brackets.
    final cardValues = {
      for (final card in tester.widgetList<MetricCard>(find.byType(MetricCard)))
        card.label: card.value,
    };
    expect(cardValues['Total Revenue (2026)'], 'Rs2,000,000 (\$7,142)');
    expect(cardValues['Total Expense (2026)'], 'Rs1,200,000 (\$4,286)');
    expect(cardValues['Total Profit (2026)'], 'Rs800,000 (\$2,856)');
    expect(cardValues['Profit Margin (2026)'], '40.0%');
    // The only record in 2026 is both the best and the worst month, and
    // with one month, the monthly average equals the yearly total.
    expect(cardValues['Best Month'], 'Rs800,000 (\$2,856)');
    expect(cardValues['Worst Month'], 'Rs800,000 (\$2,856)');
    expect(cardValues['Avg Monthly Revenue'], 'Rs2,000,000 (\$7,142)');
    final cardSecondaryValues = {
      for (final card in tester.widgetList<MetricCard>(find.byType(MetricCard)))
        card.label: card.secondaryValue,
    };
    expect(cardSecondaryValues['Best Month'], 'Jan 2026');
  });

  testWidgets(
    'shows all-time totals across every year, with the covered date range, '
    'unaffected by the year selector',
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

      expect(find.text('All-Time Totals'), findsOneWidget);
      expect(find.text('Since Jul 2022 – Jan 2026 · 2 months of data'), findsOneWidget);

      final cardValues = {
        for (final card in tester.widgetList<MetricCard>(find.byType(MetricCard)))
          card.label: card.value,
      };
      expect(cardValues['All-Time Revenue'], 'Rs3,000,000 (\$10,713)');
      expect(cardValues['All-Time Expense'], 'Rs1,800,000 (\$6,429)');
      expect(cardValues['All-Time Profit'], 'Rs1,200,000 (\$4,284)');

      // Switching the year selector must not change the all-time figures —
      // they're deliberately independent of it.
      await tester.tap(
        find.descendant(
          of: find.byType(SegmentedButton<int>),
          matching: find.text('2022'),
        ),
      );
      await tester.pumpAndSettle();

      final cardValuesAfter = {
        for (final card in tester.widgetList<MetricCard>(find.byType(MetricCard)))
          card.label: card.value,
      };
      expect(cardValuesAfter['All-Time Revenue'], 'Rs3,000,000 (\$10,713)');
    },
  );

  testWidgets('switching the year segment recomputes the stat tiles', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakeFinancialReportsRepository(
          records: [
            buildTestFinancialRecord(
              id: 'r1',
              year: 2025,
              month: 1,
              revenueRs: 500000,
              expenseRs: 400000,
            ),
            buildTestFinancialRecord(
              id: 'r2',
              year: 2026,
              month: 1,
              revenueRs: 2000000,
              expenseRs: 1200000,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<int>),
        matching: find.text('2025'),
      ),
    );
    await tester.pumpAndSettle();

    final cardValues = {
      for (final card in tester.widgetList<MetricCard>(find.byType(MetricCard)))
        card.label: card.value,
    };
    expect(cardValues['Total Revenue (2025)'], 'Rs500,000 (\$3,571)');
  });

  testWidgets(
    'the monthly charts label each bar with both month and short year',
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

      // A bare "Mar" would be ambiguous across years — the chart bars (not
      // just the detail table, which already showed "Mar 2026") must carry
      // the year too.
      expect(find.text('Mar\n26'), findsWidgets);
      expect(find.text('Mar'), findsNothing);
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

  testWidgets('the monthly detail table shows each record', (tester) async {
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
