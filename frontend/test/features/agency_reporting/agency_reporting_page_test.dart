import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/agency_reporting/application/agency_reporting_providers.dart';
import 'package:zera_erp/features/agency_reporting/domain/entities/agency_report.dart';
import 'package:zera_erp/features/agency_reporting/presentation/pages/agency_reporting_page.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';

import '../../helpers/fake_agency_reporting.dart';
import '../../helpers/fake_auth.dart';

const _superAdmin = AuthUser(
  id: 'admin-1',
  email: 'admin@zeracreative.com',
  role: 'Super Admin',
  permissions: ['reports.view'],
);

Widget _app({FakeAgencyReportingRepository? repository, AuthUser? viewer}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(viewer ?? _superAdmin)),
      ),
      agencyReportingRepositoryProvider.overrideWithValue(
        repository ?? FakeAgencyReportingRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: AgencyReportingPage())),
  );
}

void main() {
  testWidgets('renders the headline stat tiles', (tester) async {
    await tester.pumpWidget(
      _app(
        repository: FakeAgencyReportingRepository(
          report: buildTestAgencyReport(
            totalRevenue: 100000,
            totalCost: 20000,
            netProfit: 80000,
            activeMonthlyRecurringRevenue: 50000,
            oneTimeRevenue: 40000,
            activeClientsCount: 12,
            newClientsCount: 3,
            lostClientsCount: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total Revenue'), findsOneWidget);
    expect(find.text('PKR 100,000'), findsOneWidget);
    expect(find.text('Net Profit'), findsOneWidget);
    expect(find.text('PKR 80,000'), findsOneWidget);
    expect(find.text('Active Clients'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('New Clients'), findsOneWidget);
    expect(find.text('Lost Clients'), findsOneWidget);
  });

  testWidgets('shows the projects-by-status breakdown', (tester) async {
    await tester.pumpWidget(
      _app(
        repository: FakeAgencyReportingRepository(
          report: buildTestAgencyReport(
            projectsByStatus: const AgencyReportProjectsByStatus(
              active: 3,
              onHold: 1,
              completed: 5,
              cancelled: 2,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Active: 3'), findsOneWidget);
    expect(find.text('On Hold: 1'), findsOneWidget);
    expect(find.text('Completed: 5'), findsOneWidget);
    expect(find.text('Cancelled: 2'), findsOneWidget);
  });

  testWidgets('shows the top clients by profit, ranked', (tester) async {
    await tester.pumpWidget(
      _app(
        repository: FakeAgencyReportingRepository(
          report: buildTestAgencyReport(
            topClientsByProfit: const [
              AgencyReportClientProfit(
                clientId: 'c1',
                clientName: 'Big Profit Co',
                profit: 5000,
              ),
              AgencyReportClientProfit(
                clientId: 'c2',
                clientName: 'Small Profit Co',
                profit: 1000,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Big Profit Co'), findsOneWidget);
    expect(find.text('Small Profit Co'), findsOneWidget);
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
  });

  testWidgets('shows an empty state when there is no profit data', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('No project profit in this range yet.'), findsOneWidget);
  });

  testWidgets('switching the preset re-fetches with the new date range', (
    tester,
  ) async {
    final repository = FakeAgencyReportingRepository();
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    final firstFrom = repository.lastFrom;

    await tester.tap(find.text('Last Month'));
    await tester.pumpAndSettle();

    expect(repository.lastFrom, isNot(equals(firstFrom)));
  });

  testWidgets(
    'the refresh button re-fetches the report — a regression check, since '
    'this page stays mounted (never autoDisposed) when the user navigates '
    'away to create data elsewhere and back',
    (tester) async {
      final repository = FakeAgencyReportingRepository();
      await tester.pumpWidget(_app(repository: repository));
      await tester.pumpAndSettle();

      final callsBeforeRefresh = repository.callCount;

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();

      expect(repository.callCount, greaterThan(callsBeforeRefresh));
    },
  );

  testWidgets('toggling "Compare to previous period" shows delta badges', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakeAgencyReportingRepository(
          report: buildTestAgencyReport(totalRevenue: 1000),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_upward), findsNothing);
    expect(find.byIcon(Icons.arrow_downward), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Same report is returned for both the current and previous period by
    // this fake, so revenue is flat (0% change) — still exercises the
    // delta-badge code path without asserting on a specific percentage.
    expect(find.textContaining('%'), findsWidgets);
  });

  testWidgets(
    'shows an access-denied message and never fetches the report for a '
    'viewer without reports.view — a frontend-side second line of defense, '
    "since this app's IndexedStack-based nav keeps every page mounted "
    'regardless of which tab is visible',
    (tester) async {
      final repository = FakeAgencyReportingRepository();

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
      expect(find.text('Total Revenue'), findsNothing);
      expect(repository.callCount, 0);
    },
  );
}
