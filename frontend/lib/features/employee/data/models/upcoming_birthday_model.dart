import '../../../../shared/utils/photo_url.dart';
import '../../domain/entities/upcoming_birthday.dart';

class UpcomingBirthdayModel extends UpcomingBirthday {
  const UpcomingBirthdayModel({
    required super.employeeId,
    required super.fullName,
    super.profilePhotoUrl,
    required super.dateOfBirth,
    required super.daysUntil,
  });

  factory UpcomingBirthdayModel.fromJson(Map<String, dynamic> json) =>
      UpcomingBirthdayModel(
        employeeId: json['employeeId'] as String,
        fullName: json['fullName'] as String,
        profilePhotoUrl: resolvePhotoUrl(json['profilePhotoUrl'] as String?),
        dateOfBirth: json['dateOfBirth'] as String,
        daysUntil: json['daysUntil'] as int,
      );
}
