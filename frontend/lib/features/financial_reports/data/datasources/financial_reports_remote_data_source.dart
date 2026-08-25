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
}
