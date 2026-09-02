import 'package:dio/dio.dart';
import '../models/today_announcements_model.dart';

class AnnouncementsRemoteDataSource {
  const AnnouncementsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<TodayAnnouncementsModel> getToday() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/announcements/today',
    );
    return TodayAnnouncementsModel.fromJson(response.data!);
  }
}
