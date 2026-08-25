import 'package:zera_erp/features/financial_reports/domain/entities/financial_record.dart';
import 'package:zera_erp/features/financial_reports/domain/repositories/financial_reports_repository.dart';

FinancialRecord buildTestFinancialRecord({
  String id = 'record-1',
  int year = 2026,
  int month = 1,
  double revenueRs = 1000000,
  double revenueUsd = 3571,
  double expenseRs = 600000,
  double expenseUsd = 2143,
  double fxRate = 280,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final profitRs = revenueRs - expenseRs;
  final profitUsd = revenueUsd - expenseUsd;
  return FinancialRecord(
    id: id,
    year: year,
    month: month,
    revenueRs: revenueRs,
    revenueUsd: revenueUsd,
    expenseRs: expenseRs,
    expenseUsd: expenseUsd,
    fxRate: fxRate,
    profitRs: profitRs,
    profitUsd: profitUsd,
    profitPercent: revenueRs == 0 ? 0 : (profitRs / revenueRs) * 100,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    updatedAt: updatedAt ?? DateTime(2026, 1, 1),
  );
}

class FakeFinancialReportsRepository implements FinancialReportsRepository {
  FakeFinancialReportsRepository({this.records = const []});

  final List<FinancialRecord> records;

  /// Incremented on every [getRecords] call — used to confirm the
  /// permission gate short-circuits before ever fetching.
  int getRecordsCallCount = 0;

  @override
  Future<List<FinancialRecord>> getRecords() async {
    getRecordsCallCount++;
    return records;
  }
}
