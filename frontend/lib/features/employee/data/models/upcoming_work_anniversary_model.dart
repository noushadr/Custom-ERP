import '../../domain/entities/upcoming_work_anniversary.dart';

class UpcomingWorkAnniversaryModel extends UpcomingWorkAnniversary {
  const UpcomingWorkAnniversaryModel({
    required super.employeeId,
    required super.fullName,
    super.profilePhotoUrl,
    required super.joiningDate,
    required super.daysUntil,
    required super.yearsOfService,
  });

  factory UpcomingWorkAnniversaryModel.fromJson(Map<String, dynamic> json) =>
      UpcomingWorkAnniversaryModel(
        employeeId: json['employeeId'] as String,
        fullName: json['fullName'] as String,
        profilePhotoUrl: json['profilePhotoUrl'] as String?,
        joiningDate: json['joiningDate'] as String,
        daysUntil: json['daysUntil'] as int,
        yearsOfService: json['yearsOfService'] as int,
      );
}
