import 'package:dio/dio.dart';
import '../models/financial_record_model.dart';

class FinancialReportsRemoteDataSource {
  const FinancialReportsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<FinancialRecordModel>> getRecords() async {
    final response = await _dio.get<List<dynamic>>('/financial-records');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(FinancialRecordModel.fromJson)
        .toList();
  }

  Future<FinancialRecordModel> createRecord({
    required int year,
    required int month,
    required String revenueRs,
    required String revenueUsd,
    required String expenseRs,
    required String expenseUsd,
    required String fxRate,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/financial-records',
      data: {
        'year': year,
        'month': month,
        'revenueRs': revenueRs,
        'revenueUsd': revenueUsd,
        'expenseRs': expenseRs,
        'expenseUsd': expenseUsd,
        'fxRate': fxRate,
      },
    );
    return FinancialRecordModel.fromJson(response.data!);
  }

  Future<FinancialRecordModel> updateRecord(
    String id, {
    int? year,
    int? month,
    String? revenueRs,
    String? revenueUsd,
    String? expenseRs,
    String? expenseUsd,
    String? fxRate,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/financial-records/$id',
      data: {
        'year': ?year,
        'month': ?month,
        'revenueRs': ?revenueRs,
        'revenueUsd': ?revenueUsd,
        'expenseRs': ?expenseRs,
        'expenseUsd': ?expenseUsd,
        'fxRate': ?fxRate,
      },
    );
    return FinancialRecordModel.fromJson(response.data!);
  }
}
