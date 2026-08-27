import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/financial_reports/application/financial_reports_providers.dart';
import 'package:zera_erp/features/financial_reports/domain/entities/financial_record.dart';
import 'package:zera_erp/features/financial_reports/domain/exceptions/financial_record_exception.dart';
import 'package:zera_erp/features/financial_reports/presentation/pages/financial_record_editor_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_financial_reports.dart';

const _superAdmin = AuthUser(
  id: 'admin-1',
  email: 'admin@zeracreative.com',
  role: 'Super Admin',
  permissions: ['finances.manage'],
);

Widget _app({
  FakeFinancialReportsRepository? repository,
  FinancialRecord? existingRecord,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(_superAdmin)),
      ),
      financialReportsRepositoryProvider.overrideWithValue(
        repository ?? FakeFinancialReportsRepository(),
      ),
    ],
    child: MaterialApp(
      home: FinancialRecordEditorPage(existingRecord: existingRecord),
    ),
  );
}

Future<void> _fillRequiredFields(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Revenue (Rs)'),
    '1000000',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Revenue (USD)'),
    '3571',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Expense (Rs)'),
    '600000',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Expense (USD)'),
    '2143',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'FX Rate (PKR per USD)'),
    '280',
  );
}

void main() {
  testWidgets('shows a validation error when a money field is left empty', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Record'));
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsWidgets);
  });

  testWidgets('rejects a non-numeric value in a money field', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await _fillRequiredFields(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Revenue (Rs)'),
      'not a number',
    );
    await tester.tap(find.text('Create Record'));
    await tester.pumpAndSettle();

    expect(find.text('Must be a number'), findsOneWidget);
  });

  testWidgets('submits a new record with the selected month/year', (
    tester,
  ) async {
    final repository = FakeFinancialReportsRepository();
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Year'),
      '2026',
    );
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('March').last);
    await tester.pumpAndSettle();

    await _fillRequiredFields(tester);
    await tester.tap(find.text('Create Record'));
    await tester.pumpAndSettle();

    expect(repository.lastCreatedYearMonth, (2026, 3));
  });

  testWidgets('pre-fills fields when editing an existing record', (
    tester,
  ) async {
    final existing = buildTestFinancialRecord(
      year: 2025,
      month: 6,
      revenueRs: 850000,
    );
    await tester.pumpWidget(_app(existingRecord: existing));
    await tester.pumpAndSettle();

    expect(find.text('Edit Financial Record'), findsOneWidget);
    final yearField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Year'),
    );
    expect(yearField.controller?.text, '2025');
    final revenueField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Revenue (Rs)'),
    );
    expect(revenueField.controller?.text, '850000');
  });

  testWidgets('saves changes to an existing record', (tester) async {
    final repository = FakeFinancialReportsRepository();
    final existing = buildTestFinancialRecord(id: 'record-9');
    await tester.pumpWidget(
      _app(repository: repository, existingRecord: existing),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(repository.lastUpdatedId, 'record-9');
  });

  testWidgets('shows the backend error message on a duplicate month conflict', (
    tester,
  ) async {
    await tester.pumpWidget(_app(repository: _ConflictRepository()));
    await tester.pumpAndSettle();

    await _fillRequiredFields(tester);
    await tester.tap(find.text('Create Record'));
    await tester.pumpAndSettle();

    expect(
      find.text('A financial record for 3/2026 already exists.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'warns and disables Create once the selected month/year already has a '
    'record, without ever needing to submit and hit the 409',
    (tester) async {
      await tester.pumpWidget(
        _app(
          repository: FakeFinancialReportsRepository(
            records: [buildTestFinancialRecord(year: 2030, month: 3)],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Picking March is still fine — the year field hasn't been set to
      // 2030 yet, so nothing conflicts.
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('March').last);
      await tester.pumpAndSettle();

      final createButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(createButton.onPressed, isNotNull);
      expect(find.textContaining('already exists'), findsNothing);

      // Now typing the conflicting year should surface the warning and
      // disable the button — no need to fill in every money field and get
      // rejected by the server to find out.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Year'),
        '2030',
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'A record for March 2030 already exists — edit it from the '
          'Monthly Detail table instead of creating another one.',
        ),
        findsOneWidget,
      );
      final disabledButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(disabledButton.onPressed, isNull);
    },
  );

  testWidgets(
    'a taken month is shown as disabled with an "(already added)" label in '
    'the dropdown',
    (tester) async {
      await tester.pumpWidget(
        _app(
          repository: FakeFinancialReportsRepository(
            records: [buildTestFinancialRecord(year: 2030, month: 3)],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Year'),
        '2030',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      expect(find.text('March (already added)'), findsOneWidget);
      expect(find.text('April'), findsOneWidget);
    },
  );

  testWidgets(
    "editing a record doesn't flag its own month/year as a conflict, even "
    'though another record for the same month exists',
    (tester) async {
      final ownRecord = buildTestFinancialRecord(
        id: 'record-own',
        year: 2026,
        month: 3,
      );
      final repository = FakeFinancialReportsRepository(
        records: [
          ownRecord,
          buildTestFinancialRecord(id: 'record-other', year: 2026, month: 3),
        ],
      );
      await tester.pumpWidget(
        _app(repository: repository, existingRecord: ownRecord),
      );
      await tester.pumpAndSettle();

      // A genuine duplicate — a *different* record for the same
      // month/year — should still warn.
      expect(
        find.text(
          'A record for March 2026 already exists — edit it from the '
          'Monthly Detail table instead of creating another one.',
        ),
        findsOneWidget,
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    },
  );

  testWidgets(
    "editing a record with no other conflicting record doesn't warn",
    (tester) async {
      final ownRecord = buildTestFinancialRecord(
        id: 'record-own',
        year: 2026,
        month: 3,
      );
      final repository = FakeFinancialReportsRepository(
        records: [ownRecord],
      );
      await tester.pumpWidget(
        _app(repository: repository, existingRecord: ownRecord),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('already exists'), findsNothing);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    },
  );
}

class _ConflictRepository extends FakeFinancialReportsRepository {
  @override
  Future<FinancialRecord> createRecord({
    required int year,
    required int month,
    required String revenueRs,
    required String revenueUsd,
    required String expenseRs,
    required String expenseUsd,
    required String fxRate,
  }) async {
    throw const FinancialRecordException(
      'A financial record for 3/2026 already exists.',
    );
  }
}
