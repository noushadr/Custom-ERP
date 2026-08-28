import '../entities/financial_record.dart';

abstract interface class FinancialReportsRepository {
  Future<List<FinancialRecord>> getRecords();

  Future<FinancialRecord> createRecord({
    required int year,
    required int month,
    required String revenueRs,
    required String revenueUsd,
    required String expenseRs,
    required String expenseUsd,
    required String fxRate,
  });

  Future<FinancialRecord> updateRecord(
    String id, {
    int? year,
    int? month,
    String? revenueRs,
    String? revenueUsd,
    String? expenseRs,
    String? expenseUsd,
    String? fxRate,
  });
}
