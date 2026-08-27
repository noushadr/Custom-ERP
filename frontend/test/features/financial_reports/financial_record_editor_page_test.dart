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
