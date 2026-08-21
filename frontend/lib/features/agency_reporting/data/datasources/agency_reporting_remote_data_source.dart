import 'package:dio/dio.dart';
import '../models/agency_report_model.dart';

class AgencyReportingRemoteDataSource {
  const AgencyReportingRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AgencyReportModel> getReport({String? from, String? to}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/agency-reporting/report',
      queryParameters: {'from': ?from, 'to': ?to},
    );
    return AgencyReportModel.fromJson(response.data!);
  }
}
