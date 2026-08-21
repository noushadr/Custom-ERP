import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/clients/application/clients_providers.dart';
import 'package:zera_erp/features/clients/presentation/pages/client_detail_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_clients.dart';

const _superAdmin = AuthUser(
  id: 'admin-1',
  email: 'admin@zeracreative.com',
  role: 'Super Admin',
  permissions: ['clients.manage'],
);

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
            buildTestProject(
              clientId: 'client-1',
              name: 'Website Revamp',
              originalClientPrice: 1000,
              deductionRate: 20,
            ),
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
}
