import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/leads/application/leads_providers.dart';
import 'package:zera_erp/features/leads/presentation/pages/lead_import_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_leads.dart';

const _superAdmin = AuthUser(
  id: 'admin-1',
  email: 'admin@zeracreative.com',
  role: 'Super Admin',
  permissions: ['leads.manage'],
);

Widget _app({FakeLeadsRepository? repository}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(_superAdmin)),
      ),
      leadsRepositoryProvider.overrideWithValue(
        repository ?? FakeLeadsRepository(),
      ),
    ],
    child: const MaterialApp(home: LeadImportPage()),
  );
}

void main() {
  group('parseImportText', () {
    test('parses a valid row in the fixed column order', () {
      final parsed = parseImportText(
        '2026-07-15\tJane Prospect\tAcme Inc\t+92 300 1234567\t'
        'jane@acme.test\tPakistan\tSEO\tReferral\tHot lead',
      );

      expect(parsed, hasLength(1));
      final row = parsed.single.row!;
      expect(row.leadDate, '2026-07-15');
      expect(row.fullName, 'Jane Prospect');
      expect(row.companyName, 'Acme Inc');
      expect(row.phone, '+92 300 1234567');
      expect(row.email, 'jane@acme.test');
      expect(row.country, 'Pakistan');
      expect(row.serviceInterested, 'SEO');
      expect(row.leadSource, 'Referral');
      expect(row.remarks, 'Hot lead');
    });

    test('parses the "MMM D, YYYY" fallback date format', () {
      final parsed = parseImportText('Jul 5, 2026\tJane Prospect');

      expect(parsed.single.row!.leadDate, '2026-07-05');
    });

    test('leaves optional cells null when the line has fewer columns', () {
      final parsed = parseImportText('2026-07-15\tJane Prospect');

      final row = parsed.single.row!;
      expect(row.companyName, isNull);
      expect(row.phone, isNull);
    });

    test('skips blank lines entirely', () {
      final parsed = parseImportText(
        '2026-07-15\tJane Prospect\n\n   \n2026-07-16\tJohn Prospect',
      );

      expect(parsed, hasLength(2));
    });

    test('reports a missing full name as an error row', () {
      final parsed = parseImportText('2026-07-15');

      expect(parsed.single.isValid, isFalse);
      expect(parsed.single.error, 'Missing full name');
    });

    test('reports a missing date as an error row', () {
      final parsed = parseImportText('\tJane Prospect');

      expect(parsed.single.isValid, isFalse);
      expect(parsed.single.error, 'Missing date');
    });

    test('reports an unparseable date as an error row', () {
      final parsed = parseImportText('not a date\tJane Prospect');

      expect(parsed.single.isValid, isFalse);
      expect(parsed.single.error, 'Unrecognized date "not a date"');
    });
  });

  group('flagDuplicates', () {
    test('flags a row whose phone matches an existing lead', () {
      final parsed = parseImportText(
        '2026-07-15\tJohn New\t\t+92 300 1234567',
      );
      final flagged = flagDuplicates(parsed, [
        buildTestLead(fullName: 'Jane Existing', phone: '+923001234567'),
      ]);

      expect(flagged.single.isDuplicate, isTrue);
      expect(
        flagged.single.duplicateReason,
        'Same phone as existing lead "Jane Existing"',
      );
    });

    test(
      'ignores phone formatting differences when comparing to an existing lead',
      () {
        final parsed = parseImportText('2026-07-15\tJohn New\t\t923001234567');
        final flagged = flagDuplicates(parsed, [
          buildTestLead(fullName: 'Jane Existing', phone: '+92-300-1234567'),
        ]);

        expect(flagged.single.isDuplicate, isTrue);
      },
    );

    test('flags a row whose email matches an existing lead, case-insensitively', () {
      final parsed = parseImportText(
        '2026-07-15\tJohn New\t\t\tJANE@ACME.TEST',
      );
      final flagged = flagDuplicates(parsed, [
        buildTestLead(fullName: 'Jane Existing', email: 'jane@acme.test'),
      ]);

      expect(flagged.single.isDuplicate, isTrue);
      expect(
        flagged.single.duplicateReason,
        'Same email as existing lead "Jane Existing"',
      );
    });

    test('flags the second of two rows in the same paste sharing a phone', () {
      final parsed = parseImportText(
        '2026-07-15\tJohn New\t\t+923001234567\n'
        '2026-07-16\tJohn Duplicate\t\t+923001234567',
      );
      final flagged = flagDuplicates(parsed, const []);

      expect(flagged[0].isDuplicate, isFalse);
      expect(flagged[1].isDuplicate, isTrue);
      expect(flagged[1].duplicateReason, 'Same phone as row 1 above');
    });

    test('never flags a row with neither phone nor email', () {
      final parsed = parseImportText(
        '2026-07-15\tJohn New\n2026-07-16\tJohn Also New',
      );
      final flagged = flagDuplicates(parsed, [
        buildTestLead(fullName: 'Someone Else'),
      ]);

      expect(flagged.every((row) => !row.isDuplicate), isTrue);
    });

    test('passes error rows through unchanged', () {
      final parsed = parseImportText('not a date\tJane Prospect');
      final flagged = flagDuplicates(parsed, const []);

      expect(flagged.single.isValid, isFalse);
      expect(flagged.single.isDuplicate, isFalse);
    });
  });

  testWidgets('previews parsed rows as they are typed', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      '2026-07-15\tJane Prospect\n'
      'not a date\tJohn Prospect',
    );
    await tester.pumpAndSettle();

    expect(find.text('2 rows found — 1 ready to import, 1 with errors (skipped).'), findsOneWidget);
    expect(find.text('Jane Prospect'), findsOneWidget);
    expect(find.text('John Prospect'), findsOneWidget);
    expect(find.text('Unrecognized date "not a date"'), findsOneWidget);
  });

  testWidgets('imports only the valid rows and shows a success message', (
    tester,
  ) async {
    final repository = FakeLeadsRepository();
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      '2026-07-15\tJane Prospect\n'
      'not a date\tJohn Prospect',
    );
    await tester.pumpAndSettle();

    final importButton = find.text('Import 1 Lead');
    await tester.ensureVisible(importButton);
    await tester.tap(importButton);
    await tester.pumpAndSettle();

    expect(repository.lastImportedRows, hasLength(1));
    expect(repository.lastImportedRows!.single.fullName, 'Jane Prospect');
    expect(find.text('Imported 1 lead.'), findsOneWidget);
  });

  testWidgets(
    'flags a possible duplicate against an existing lead, excludes it from '
    'the import by default, and includes it once checked',
    (tester) async {
      final repository = FakeLeadsRepository(
        leads: [
          buildTestLead(fullName: 'Jane Existing', phone: '+923001234567'),
        ],
      );
      await tester.pumpWidget(_app(repository: repository));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        '2026-07-15\tJohn New\t\t+92 300 1234567',
      );
      await tester.pumpAndSettle();

      expect(
        find.text('1 row found — 0 ready to import, 1 possible duplicate (excluded by default).'),
        findsOneWidget,
      );
      expect(
        find.text('Same phone as existing lead "Jane Existing" — skipped'),
        findsOneWidget,
      );

      final importButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(importButton.onPressed, isNull);

      final checkbox = find.byType(Checkbox);
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      expect(
        find.text('Same phone as existing lead "Jane Existing" — will be imported'),
        findsOneWidget,
      );
      expect(find.text('Import 1 Lead'), findsOneWidget);

      final importNowButton = find.text('Import 1 Lead');
      await tester.ensureVisible(importNowButton);
      await tester.tap(importNowButton);
      await tester.pumpAndSettle();

      expect(repository.lastImportedRows, hasLength(1));
      expect(repository.lastImportedRows!.single.fullName, 'John New');
    },
  );

  testWidgets('the import button is disabled until at least one row is valid', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    await tester.enterText(
      find.byType(TextField),
      '2026-07-15\tJane Prospect',
    );
    await tester.pumpAndSettle();

    final enabledButton = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(enabledButton.onPressed, isNotNull);
  });
}
