import 'package:dio/dio.dart';
import '../models/expense_model.dart';
import '../models/financial_summary_model.dart';

class FinancesRemoteDataSource {
  const FinancesRemoteDataSource(this._dio);

  final Dio _dio;

  Future<FinancialSummaryModel> getSummary({String? from, String? to}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/finances/summary',
      queryParameters: {'from': ?from, 'to': ?to},
    );
    return FinancialSummaryModel.fromJson(response.data!);
  }

  Future<List<ExpenseModel>> getExpenses({String? from, String? to}) async {
    final response = await _dio.get<List<dynamic>>(
      '/expenses',
      queryParameters: {'from': ?from, 'to': ?to},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(ExpenseModel.fromJson)
        .toList();
  }

  Future<ExpenseModel> createExpense({
    required String category,
    required double amount,
    required String date,
    String? payeeName,
    String? notes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/expenses',
      data: {
        'category': category,
        'amount': amount,
        'date': date,
        'payeeName': ?payeeName,
        'notes': ?notes,
      },
    );
    return ExpenseModel.fromJson(response.data!);
  }

  Future<ExpenseModel> updateExpense(
    String id, {
    String? category,
    double? amount,
    String? date,
    String? payeeName,
    String? notes,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/expenses/$id',
      data: {
        'category': ?category,
        'amount': ?amount,
        'date': ?date,
        'payeeName': ?payeeName,
        'notes': ?notes,
      },
    );
    return ExpenseModel.fromJson(response.data!);
  }
}
