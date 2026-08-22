import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/finances/application/finances_providers.dart';
import 'package:zera_erp/features/finances/domain/entities/expense_category.dart';
import 'package:zera_erp/features/finances/presentation/pages/finances_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_finances.dart';

const _superAdmin = AuthUser(
  id: 'admin-1',
  email: 'admin@zeracreative.com',
  role: 'Super Admin',
  permissions: ['finances.manage'],
);

Widget _app({FakeFinancesRepository? repository, AuthUser? viewer}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(viewer ?? _superAdmin)),
      ),
      financesRepositoryProvider.overrideWithValue(
        repository ?? FakeFinancesRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: FinancesPage())),
  );
}

void main() {
  testWidgets('renders the headline stat tiles', (tester) async {
    await tester.pumpWidget(
      _app(
        repository: FakeFinancesRepository(
          summary: buildTestFinancialSummary(
            deductions: 20000,
            totalExpenses: 5000,
            currentMonthlyPayroll: 30000,
            outstandingInvoicesTotal: 8000,
            outstandingInvoicesCount: 2,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deductions'), findsOneWidget);
    expect(find.text('PKR 20,000'), findsOneWidget);
    expect(find.text('Total Expenses'), findsOneWidget);
    expect(find.text('PKR 5,000'), findsOneWidget);
    expect(find.text('Current Monthly Payroll'), findsOneWidget);
    expect(find.text('PKR 30,000'), findsOneWidget);
    expect(find.text('Outstanding Invoices'), findsOneWidget);
    expect(find.text('2 project(s)'), findsOneWidget);
  });

  testWidgets(
    'does not duplicate Agency Reporting\'s revenue/cost/profit stats',
    (tester) async {
      await tester.pumpWidget(
        _app(repository: FakeFinancesRepository(summary: buildTestFinancialSummary())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gross Revenue'), findsNothing);
      expect(find.text('Project Costs'), findsNothing);
      expect(find.text('Net Profit'), findsNothing);
    },
  );

  testWidgets('shows the expenses-by-category breakdown', (tester) async {
    await tester.pumpWidget(
      _app(
        repository: FakeFinancesRepository(
          summary: buildTestFinancialSummary(
            expensesByCategory: const {
              ExpenseCategory.softwareTools: 1200,
              ExpenseCategory.marketing: 800,
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Software & Tools: PKR 1,200'), findsOneWidget);
    expect(find.text('Marketing: PKR 800'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no expenses', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(
      find.text('No expenses recorded in this range yet.'),
      findsWidgets,
    );
  });

  testWidgets('lists expenses with category, payee, date, and amount', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        repository: FakeFinancesRepository(
          expenses: [
            buildTestExpense(
              category: ExpenseCategory.rentUtilities,
              amount: 5000,
              date: '2026-08-05',
              payeeName: 'Landlord Co',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rent & Utilities'), findsOneWidget);
    expect(find.text('Landlord Co'), findsOneWidget);
    expect(find.text('PKR 5,000.00'), findsOneWidget);
  });

  testWidgets('adding an expense submits the form and refreshes', (
    tester,
  ) async {
    final repository = FakeFinancesRepository();
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Add Expense'));
    await tester.tap(find.text('Add Expense'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Amount (PKR)'), '250');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(repository.lastCreatedExpenseAmount, 250);
    expect(repository.lastCreatedExpenseCategory, ExpenseCategory.other);
  });

  testWidgets('editing an expense pre-fills the dialog and submits changes', (
    tester,
  ) async {
    final repository = FakeFinancesRepository(
      expenses: [
        buildTestExpense(
          id: 'expense-9',
          category: ExpenseCategory.marketing,
          amount: 300,
          payeeName: 'Ad Agency',
        ),
      ],
    );
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Ad Agency'));
    await tester.tap(find.text('Ad Agency'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Expense'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Amount (PKR)'), '450');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(repository.lastUpdatedExpenseId, 'expense-9');
    expect(repository.lastUpdatedExpenseAmount, 450);
  });

  testWidgets('switching the preset re-fetches with the new date range', (
    tester,
  ) async {
    final repository = FakeFinancesRepository();
    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    final callsBeforeSwitch = repository.getSummaryCallCount;

    await tester.tap(find.text('Last Month'));
    await tester.pumpAndSettle();

    expect(repository.getSummaryCallCount, greaterThan(callsBeforeSwitch));
  });

  testWidgets(
    'the refresh button re-fetches the summary — a regression check, since '
    'this page stays mounted (never autoDisposed) when the user navigates '
    'away to create data elsewhere and back',
    (tester) async {
      final repository = FakeFinancesRepository();
      await tester.pumpWidget(_app(repository: repository));
      await tester.pumpAndSettle();

      final callsBeforeRefresh = repository.getSummaryCallCount;

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();

      expect(repository.getSummaryCallCount, greaterThan(callsBeforeRefresh));
    },
  );

  testWidgets(
    'shows an access-denied message and never fetches the summary for a '
    'viewer without finances.manage — a frontend-side second line of '
    "defense, since this app's IndexedStack-based nav keeps every page "
    'mounted regardless of which tab is visible',
    (tester) async {
      final repository = FakeFinancesRepository();

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
      expect(find.text('Deductions'), findsNothing);
      expect(repository.getSummaryCallCount, 0);
    },
  );
}
