import '../entities/financial_record.dart';

abstract interface class FinancialReportsRepository {
  Future<List<FinancialRecord>> getRecords();
}
