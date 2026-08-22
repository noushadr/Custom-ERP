import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/clients/application/clients_providers.dart';
import 'package:zera_erp/features/clients/domain/entities/client_health_factor.dart';
import 'package:zera_erp/features/clients/domain/entities/client_health_status.dart';
import 'package:zera_erp/features/clients/presentation/pages/client_detail_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_clients.dart';

const _superAdmin = AuthUser(
  id: 'admin-1',
  email: 'admin@zeracreative.com',
  role: 'Super Admin',
  permissions: ['clients.manage'],
);

Future<void> _useTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app({required FakeClientsRepository repository, String clientId = 'client-1'}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(_superAdmin)),
      ),
      clientsRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(home: ClientDetailPage(clientId: clientId)),
  );
}

void main() {
  testWidgets('shows client info, contact details, and its projects', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          clients: [
            buildTestClient(
              companyName: 'Acme Co',
              industry: 'Retail',
              primaryContactEmail: 'contact@acme.test',
            ),
          ],
          projects: [
            buildTestProject(clientId: 'client-1', name: 'Website Revamp'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acme Co'), findsOneWidget);
    expect(find.text('Retail'), findsOneWidget);
    expect(find.text('Email: contact@acme.test'), findsOneWidget);
    expect(find.text('Website Revamp'), findsOneWidget);
  });

  testWidgets('shows an empty-state message when the client has no projects', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          clients: [buildTestClient(companyName: 'Acme Co')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No projects for this client yet.'), findsOneWidget);
  });

  testWidgets('shows an Archived badge for an archived client', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          clients: [buildTestClient(companyName: 'Acme Co', isArchived: true)],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Archived'), findsOneWidget);
  });

  testWidgets('shows the health status badge, factor chips, and notes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          clients: [
            buildTestClient(
              companyName: 'Acme Co',
              healthStatus: ClientHealthStatus.atRisk,
              healthFactors: [
                ClientHealthFactor.payment,
                ClientHealthFactor.delays,
              ],
              healthNotes: 'Invoice overdue 30 days',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('At Risk'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Delays'), findsOneWidget);
    expect(find.text('Invoice overdue 30 days'), findsOneWidget);
  });

  testWidgets('shows health history entries newest-first order as returned', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          clients: [buildTestClient(companyName: 'Acme Co')],
          clientHealthHistory: [
            buildTestClientHealthHistoryEntry(
              previousStatus: ClientHealthStatus.healthy,
              newStatus: ClientHealthStatus.atRisk,
              factors: [ClientHealthFactor.communication],
              notes: 'Missed calls',
              actorName: 'Jane Admin',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('By Jane Admin'), findsOneWidget);
    expect(find.text('Communication'), findsOneWidget);
    expect(find.text('Missed calls'), findsOneWidget);
  });

  testWidgets('shows an empty state when there is no health history', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          clients: [buildTestClient(companyName: 'Acme Co')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No health updates yet.'), findsOneWidget);
  });

  testWidgets('updating health submits status, factors, and notes', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = FakeClientsRepository(
      clients: [buildTestClient(companyName: 'Acme Co')],
    );
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update Health'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Status'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('At Risk').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Payment'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Notes'),
      'Invoice overdue',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(repository.lastHealthUpdateClientId, 'client-1');
    expect(repository.lastHealthUpdateStatus, ClientHealthStatus.atRisk);
    expect(repository.lastHealthUpdateFactors, [ClientHealthFactor.payment]);
    expect(repository.lastHealthUpdateNotes, 'Invoice overdue');
  });

  testWidgets(
    'updating health invalidates the client list so the status badge refreshes',
    (tester) async {
      await _useTallSurface(tester);
      final repository = FakeClientsRepository(
        clients: [buildTestClient(companyName: 'Acme Co')],
      );
      await tester.pumpWidget(_app(repository: repository));
      await tester.pumpAndSettle();

      final callsBeforeSave = repository.getClientsCallCount;

      await tester.tap(find.text('Update Health'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'Status'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('At Risk').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // A regression check: updateClientHealth alone isn't enough — the
      // client list/detail providers (which the health badge reads) must
      // also be invalidated so the badge doesn't show stale data.
      expect(
        repository.getClientsCallCount,
        greaterThan(callsBeforeSave),
      );
    },
  );
}
