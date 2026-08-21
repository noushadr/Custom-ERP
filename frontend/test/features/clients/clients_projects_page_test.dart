import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/clients/application/clients_providers.dart';
import 'package:zera_erp/features/clients/presentation/pages/clients_projects_page.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_clients.dart';
import '../../helpers/fake_employee.dart';

const _superAdmin = AuthUser(
  id: 'admin-1',
  email: 'admin@zeracreative.com',
  role: 'Super Admin',
  permissions: ['clients.manage'],
);

Widget _app({FakeClientsRepository? repository}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(_superAdmin)),
      ),
      employeeRepositoryProvider.overrideWithValue(FakeEmployeeRepository()),
      clientsRepositoryProvider.overrideWithValue(
        repository ?? FakeClientsRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: ClientsProjectsPage())),
  );
}

void main() {
  testWidgets('renders the summary stat tiles', (tester) async {
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          projectsSummary: buildTestProjectsSummary(
            activeCount: 3,
            onHoldCount: 1,
            completedCount: 5,
            activeMonthlyRecurringRevenue: 20000,
            oneTimeRevenueThisYear: 50000,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
    expect(find.text('Active Projects'), findsOneWidget);
    expect(find.text('Monthly Recurring Revenue'), findsOneWidget);
    expect(find.text('One-time Revenue (This Year)'), findsOneWidget);
  });

  testWidgets('shows the Projects tab by default with New Project/New Client buttons', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          projects: [buildTestProject(name: 'Website Revamp')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Website Revamp'), findsOneWidget);
    expect(find.text('New Project'), findsOneWidget);
    expect(find.text('New Client'), findsOneWidget);
  });

  testWidgets('switching to the Clients tab shows clients instead of projects', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          projects: [buildTestProject(name: 'Website Revamp')],
          clients: [buildTestClient(companyName: 'Acme Co')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acme Co'), findsNothing);

    await tester.tap(find.text('Clients'));
    await tester.pumpAndSettle();

    expect(find.text('Acme Co'), findsOneWidget);
    expect(find.text('Website Revamp'), findsNothing);
  });

  testWidgets('shows an empty state when there are no projects', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('No projects yet.'), findsOneWidget);
  });
}
