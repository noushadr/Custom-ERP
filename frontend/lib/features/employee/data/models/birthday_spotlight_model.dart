import '../../domain/entities/birthday_spotlight.dart';
import 'upcoming_birthday_model.dart';

class BirthdaySpotlightModel extends BirthdaySpotlight {
  const BirthdaySpotlightModel({
    required super.thisMonth,
    required super.nextMonth,
  });

  factory BirthdaySpotlightModel.fromJson(Map<String, dynamic> json) =>
      BirthdaySpotlightModel(
        thisMonth: (json['thisMonth'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(UpcomingBirthdayModel.fromJson)
            .toList(),
        nextMonth: (json['nextMonth'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(UpcomingBirthdayModel.fromJson)
            .toList(),
      );
}
