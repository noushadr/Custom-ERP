import '../entities/expense.dart';
import '../entities/financial_summary.dart';

abstract interface class FinancesRepository {
  Future<FinancialSummary> getSummary({String? from, String? to});

  Future<List<Expense>> getExpenses({String? from, String? to});
  Future<Expense> createExpense({
    required String category,
    required double amount,
    required String date,
    String? payeeName,
    String? notes,
  });
  Future<Expense> updateExpense(
    String id, {
    String? category,
    double? amount,
    String? date,
    String? payeeName,
    String? notes,
  });
}
