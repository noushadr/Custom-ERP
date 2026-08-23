import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/leads/application/leads_providers.dart';
import 'package:zera_erp/features/leads/presentation/pages/leads_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_leads.dart';

const _superAdmin = AuthUser(
  id: 'admin-1',
  email: 'admin@zeracreative.com',
  role: 'Super Admin',
  permissions: ['leads.manage'],
);

Widget _app({FakeLeadsRepository? repository, AuthUser? viewer}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(viewer ?? _superAdmin)),
      ),
      leadsRepositoryProvider.overrideWithValue(
        repository ?? FakeLeadsRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: LeadsPage())),
  );
}

void main() {
  testWidgets('shows an empty state when there are no leads', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('No leads yet.'), findsOneWidget);
    expect(find.text('New Lead'), findsOneWidget);
  });

  testWidgets('lists leads with company/source/country subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakeLeadsRepository(
          leads: [
            buildTestLead(
              fullName: 'Jane Prospect',
              companyName: 'Acme Inc',
              leadSource: 'Referral',
              country: 'Pakistan',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jane Prospect'), findsOneWidget);
    expect(find.text('Acme Inc · Referral · Pakistan'), findsOneWidget);
  });

  testWidgets('excludes archived leads by default, shows them when toggled', (
    tester,
  ) async {
    final repository = FakeLeadsRepository(
      leads: [
        buildTestLead(
          id: 'l1',
          fullName: 'Active Lead',
          isArchived: false,
        ),
        buildTestLead(
          id: 'l2',
          fullName: 'Archived Lead',
          isArchived: true,
        ),
      ],
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Active Lead'), findsOneWidget);
    expect(find.text('Archived Lead'), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Active Lead'), findsOneWidget);
    expect(find.text('Archived Lead'), findsOneWidget);
  });

  testWidgets(
    'shows an access-denied message instead of any lead data for a viewer '
    'without leads.manage',
    (tester) async {
      final repository = FakeLeadsRepository(
        leads: [buildTestLead(fullName: 'Should Not Be Visible')],
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
      expect(find.text('Should Not Be Visible'), findsNothing);
      expect(repository.getLeadsCallCount, 0);
    },
  );
}
