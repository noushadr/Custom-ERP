import '../../domain/entities/notification_mute_preference.dart';

class NotificationMutePreferenceModel extends NotificationMutePreference {
  const NotificationMutePreferenceModel({
    required super.category,
    required super.label,
    required super.muted,
  });

  factory NotificationMutePreferenceModel.fromJson(
    Map<String, dynamic> json,
  ) => NotificationMutePreferenceModel(
    category: json['category'] as String,
    label: json['label'] as String,
    muted: json['muted'] as bool,
  );
}
