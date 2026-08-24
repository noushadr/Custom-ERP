import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/leads/application/leads_providers.dart';
import 'package:zera_erp/features/leads/domain/entities/lead.dart';
import 'package:zera_erp/features/leads/presentation/pages/lead_editor_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_leads.dart';

const _superAdmin = AuthUser(
  id: 'admin-1',
  email: 'admin@zeracreative.com',
  role: 'Super Admin',
  permissions: ['leads.manage'],
);

Widget _app({FakeLeadsRepository? repository, Lead? existingLead}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(_superAdmin)),
      ),
      leadsRepositoryProvider.overrideWithValue(
        repository ?? FakeLeadsRepository(),
      ),
    ],
    child: MaterialApp(
      home: LeadEditorPage(existingLead: existingLead),
    ),
  );
}

void main() {
  testWidgets('shows a validation error when full name is empty', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Lead'));
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('submits a new lead', (tester) async {
    final repository = FakeLeadsRepository();
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name'),
      'New Prospect',
    );
    await tester.tap(find.text('Create Lead'));
    await tester.pumpAndSettle();

    expect(repository.lastCreatedFullName, 'New Prospect');
  });

  testWidgets('pre-fills fields when editing an existing lead', (
    tester,
  ) async {
    final existing = buildTestLead(fullName: 'Existing Prospect');
    await tester.pumpWidget(_app(existingLead: existing));
    await tester.pumpAndSettle();

    expect(find.text('Edit Lead'), findsOneWidget);
    final nameField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Full name'),
    );
    expect(nameField.controller?.text, 'Existing Prospect');
  });

  testWidgets('saves changes to an existing lead', (tester) async {
    final repository = FakeLeadsRepository();
    final existing = buildTestLead(id: 'lead-9', fullName: 'Existing Prospect');
    await tester.pumpWidget(_app(repository: repository, existingLead: existing));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(repository.lastUpdatedId, 'lead-9');
  });
}
