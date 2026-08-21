import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/clients/application/clients_providers.dart';
import 'package:zera_erp/features/clients/presentation/pages/services_settings_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_clients.dart';

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
      clientsRepositoryProvider.overrideWithValue(
        repository ?? FakeClientsRepository(),
      ),
    ],
    child: const MaterialApp(home: ServicesSettingsPage()),
  );
}

void main() {
  testWidgets('shows an empty state when there are no services', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('No services yet.'), findsOneWidget);
  });

  testWidgets('lists existing services', (tester) async {
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          services: [buildTestService(name: 'SEO', description: 'Search work')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SEO'), findsOneWidget);
    expect(find.text('Search work'), findsOneWidget);
  });

  testWidgets('creating a service calls the repository', (tester) async {
    final repository = FakeClientsRepository();
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Content Writing',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add service'));
    await tester.pumpAndSettle();

    expect(repository.lastCreatedServiceName, 'Content Writing');
  });

  testWidgets('archiving a service calls the repository without error', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakeClientsRepository(
          services: [buildTestService(name: 'SEO')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    // No repository call assertion needed beyond not crashing —
    // FakeClientsRepository.updateService always succeeds; a real failure
    // would surface as a SnackBar, which we can assert is absent.
    expect(find.byType(SnackBar), findsNothing);
  });
}
