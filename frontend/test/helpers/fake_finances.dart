import 'package:zera_erp/features/finances/domain/entities/expense.dart';
import 'package:zera_erp/features/finances/domain/entities/expense_category.dart';
import 'package:zera_erp/features/finances/domain/entities/financial_summary.dart';
import 'package:zera_erp/features/finances/domain/repositories/finances_repository.dart';

Expense buildTestExpense({
  String id = 'expense-1',
  String category = ExpenseCategory.other,
  double amount = 100,
  String date = '2026-08-01',
  String? payeeName,
  String? notes,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Expense(
    id: id,
    category: category,
    amount: amount,
    date: date,
    payeeName: payeeName,
    notes: notes,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    updatedAt: updatedAt ?? DateTime(2026, 1, 1),
  );
}

FinancialSummary buildTestFinancialSummary({
  String from = '2026-08-01',
  String to = '2026-08-21',
  double grossRevenue = 0,
  double deductions = 0,
  double projectCosts = 0,
  double totalExpenses = 0,
  Map<String, double> expensesByCategory = const {},
  double netProfit = 0,
  double currentMonthlyPayroll = 0,
  double outstandingInvoicesTotal = 0,
  int outstandingInvoicesCount = 0,
}) {
  return FinancialSummary(
    from: from,
    to: to,
    grossRevenue: grossRevenue,
    deductions: deductions,
    projectCosts: projectCosts,
    totalExpenses: totalExpenses,
    expensesByCategory: expensesByCategory,
    netProfit: netProfit,
    currentMonthlyPayroll: currentMonthlyPayroll,
    outstandingInvoicesTotal: outstandingInvoicesTotal,
    outstandingInvoicesCount: outstandingInvoicesCount,
  );
}

class FakeFinancesRepository implements FinancesRepository {
  FakeFinancesRepository({this.summary, this.expenses = const []});

  final FinancialSummary? summary;
  final List<Expense> expenses;

  /// The arguments passed to the most recent [createExpense] call.
  String? lastCreatedExpenseCategory;
  double? lastCreatedExpenseAmount;

  /// The arguments passed to the most recent [updateExpense] call.
  String? lastUpdatedExpenseId;
  String? lastUpdatedExpenseCategory;
  double? lastUpdatedExpenseAmount;

  /// Incremented on every [getSummary] call — used to confirm a refresh
  /// action actually re-fetched rather than reading a cached value.
  int getSummaryCallCount = 0;

  @override
  Future<FinancialSummary> getSummary({String? from, String? to}) async {
    getSummaryCallCount++;
    return summary ??
        buildTestFinancialSummary(from: from ?? '2026-08-01', to: to ?? '2026-08-21');
  }

  @override
  Future<List<Expense>> getExpenses({String? from, String? to}) async =>
      expenses;

  @override
  Future<Expense> createExpense({
    required String category,
    required double amount,
    required String date,
    String? payeeName,
    String? notes,
  }) async {
    lastCreatedExpenseCategory = category;
    lastCreatedExpenseAmount = amount;
    return buildTestExpense(
      category: category,
      amount: amount,
      date: date,
      payeeName: payeeName,
      notes: notes,
    );
  }

  @override
  Future<Expense> updateExpense(
    String id, {
    String? category,
    double? amount,
    String? date,
    String? payeeName,
    String? notes,
  }) async {
    lastUpdatedExpenseId = id;
    lastUpdatedExpenseCategory = category;
    lastUpdatedExpenseAmount = amount;
    return buildTestExpense(
      id: id,
      category: category ?? ExpenseCategory.other,
      amount: amount ?? 0,
      date: date ?? '2026-08-01',
      payeeName: payeeName,
      notes: notes,
    );
  }
}
