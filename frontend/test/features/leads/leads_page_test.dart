import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/leads/application/leads_providers.dart';
import 'package:zera_erp/features/leads/presentation/pages/leads_page.dart';
import 'package:zera_erp/shared/widgets/metric_card.dart';

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

  testWidgets(
    'does not repeat a "Leads" heading — the top bar already shows it',
    (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Leads'), findsNothing);
    },
  );

  testWidgets('shows the spreadsheet-style column headers', (tester) async {
    await tester.pumpWidget(
      _app(repository: FakeLeadsRepository(leads: [buildTestLead()])),
    );
    await tester.pumpAndSettle();

    for (final label in [
      'Date',
      'Full Name',
      'Company',
      'Phone',
      'Email',
      'Country',
      'Service Interested',
      'Lead Source',
      'Remarks',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('lists a lead with every field in its own aligned column', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakeLeadsRepository(
          leads: [
            buildTestLead(
              leadDate: '2026-03-05',
              fullName: 'Jane Prospect',
              companyName: 'Acme Inc',
              leadSource: 'Referral',
              country: 'Pakistan',
              phone: '+1 555 0100',
              email: 'jane@acme.test',
              serviceInterested: 'SEO',
              remarks: 'Interested',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026-03-05'), findsOneWidget);
    expect(find.text('Jane Prospect'), findsOneWidget);
    expect(find.text('Acme Inc'), findsOneWidget);
    // Phone and email are separate columns, not one shared cell.
    expect(find.text('+1 555 0100'), findsOneWidget);
    expect(find.text('jane@acme.test'), findsOneWidget);
    expect(find.text('Interested'), findsOneWidget);
    // Service/source also appear in the "Top ..." breakdown panels above
    // the table, so these are expected to show up more than once. Country
    // renders as a flag + short code (🇵🇰 PK), not the full name.
    expect(find.text('🇵🇰 PK'), findsAtLeastNWidgets(1));
    expect(find.text('Pakistan'), findsNothing);
    expect(find.text('SEO'), findsAtLeastNWidgets(1));
    expect(find.text('Referral'), findsAtLeastNWidgets(1));
  });

  testWidgets(
    'maps known country values to their short code, case-insensitively, '
    'and leaves an unrecognized value as-is',
    (tester) async {
      await tester.pumpWidget(
        _app(
          repository: FakeLeadsRepository(
            leads: [
              buildTestLead(id: 'l1', fullName: 'A', country: 'Pakistan'),
              buildTestLead(id: 'l2', fullName: 'B', country: 'saudia'),
              buildTestLead(id: 'l3', fullName: 'C', country: 'Narnia'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('🇵🇰 PK'), findsAtLeastNWidgets(1));
      expect(find.text('🇸🇦 KSA'), findsAtLeastNWidgets(1));
      expect(find.text('Narnia'), findsAtLeastNWidgets(1));
    },
  );

  testWidgets('shows an em dash for missing optional fields', (tester) async {
    await tester.pumpWidget(
      _app(
        repository: FakeLeadsRepository(
          leads: [
            buildTestLead(
              fullName: 'Bare Lead',
              companyName: null,
              leadSource: null,
              country: null,
              serviceInterested: null,
              remarks: null,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bare Lead'), findsOneWidget);
    // Company, Phone, Email, Country, Service Interested, Lead Source, Remarks.
    expect(find.text('—'), findsNWidgets(7));
  });

  testWidgets('shows summary stat tiles', (tester) async {
    final now = DateTime.now();
    String isoDate(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    await tester.pumpWidget(
      _app(
        repository: FakeLeadsRepository(
          leads: [
            buildTestLead(id: 'l1', leadDate: isoDate(now)),
            buildTestLead(id: 'l2', leadDate: '2020-01-01'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scoped to MetricCard specifically — breakdown panels below also show
    // plain count numbers, so a bare find.text('1') would be ambiguous.
    final cardValues = {
      for (final card in tester.widgetList<MetricCard>(find.byType(MetricCard)))
        card.label: card.value,
    };

    expect(cardValues['Total Leads'], '2');
    expect(cardValues['New This Week'], '1');
    expect(cardValues['New This Month'], '1');
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
