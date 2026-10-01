import 'package:dio/dio.dart';
import '../models/app_notification_model.dart';
import '../models/notification_mute_preference_model.dart';

class NotificationsRemoteDataSource {
  const NotificationsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<AppNotificationModel>> getMine({bool unreadOnly = false}) async {
    final response = await _dio.get<List<dynamic>>(
      '/notifications',
      queryParameters: {if (unreadOnly) 'unreadOnly': 'true'},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(AppNotificationModel.fromJson)
        .toList();
  }

  Future<void> markRead(String id) async {
    await _dio.patch<void>('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.patch<void>('/notifications/read-all');
  }

  Future<List<NotificationMutePreferenceModel>> getMutePreferences() async {
    final response = await _dio.get<List<dynamic>>(
      '/notifications/mute-preferences',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(NotificationMutePreferenceModel.fromJson)
        .toList();
  }

  Future<void> setMutePreference(String category, bool muted) async {
    await _dio.patch<void>(
      '/notifications/mute-preferences',
      data: {'category': category, 'muted': muted},
    );
  }
}
