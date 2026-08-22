import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/clients/application/clients_providers.dart';
import 'package:zera_erp/features/clients/presentation/pages/client_editor_page.dart';

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
    child: const MaterialApp(home: ClientEditorPage()),
  );
}

void main() {
  testWidgets('shows a validation error when company name is empty', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Client'));
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('submits a new client', (tester) async {
    final repository = FakeClientsRepository();
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Company name'),
      'New Client Co',
    );
    await tester.tap(find.text('Create Client'));
    await tester.pumpAndSettle();

    expect(repository.lastCreatedCompanyName, 'New Client Co');
  });

  testWidgets('pre-fills fields when editing an existing client', (
    tester,
  ) async {
    final existing = buildTestClient(companyName: 'Existing Client');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => PresetAuthController(AuthAuthenticated(_superAdmin)),
          ),
          clientsRepositoryProvider.overrideWithValue(FakeClientsRepository()),
        ],
        child: MaterialApp(home: ClientEditorPage(existingClient: existing)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Client'), findsOneWidget);
    final companyField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Company name'),
    );
    expect(companyField.controller?.text, 'Existing Client');
  });
}
