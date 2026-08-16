import 'package:dio/dio.dart';
import '../models/holiday_model.dart';

class HolidayRemoteDataSource {
  const HolidayRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<HolidayModel>> getAll({int? year}) async {
    final response = await _dio.get<List<dynamic>>(
      '/holidays',
      queryParameters: year == null ? null : {'year': year.toString()},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(HolidayModel.fromJson)
        .toList();
  }

  Future<HolidayModel> create({
    required String name,
    required String date,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/holidays',
      data: {'name': name, 'date': date},
    );
    return HolidayModel.fromJson(response.data!);
  }

  Future<HolidayModel> update(String id, {String? name, String? date}) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/holidays/$id',
      data: {'name': name, 'date': date},
    );
    return HolidayModel.fromJson(response.data!);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/holidays/$id');
  }
}
