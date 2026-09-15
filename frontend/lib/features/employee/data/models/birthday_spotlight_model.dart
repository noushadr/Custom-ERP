import '../../domain/entities/birthday_spotlight.dart';
import 'upcoming_birthday_model.dart';

class BirthdaySpotlightModel extends BirthdaySpotlight {
  const BirthdaySpotlightModel({super.last, super.upcoming});

  factory BirthdaySpotlightModel.fromJson(Map<String, dynamic> json) =>
      BirthdaySpotlightModel(
        last: json['last'] == null
            ? null
            : UpcomingBirthdayModel.fromJson(
                json['last'] as Map<String, dynamic>,
              ),
        upcoming: json['upcoming'] == null
            ? null
            : UpcomingBirthdayModel.fromJson(
                json['upcoming'] as Map<String, dynamic>,
              ),
      );
}
