import '../../domain/entities/holiday.dart';

class HolidayModel extends Holiday {
  const HolidayModel({
    required super.id,
    required super.name,
    required super.date,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) => HolidayModel(
    id: json['id'] as String,
    name: json['name'] as String,
    date: json['date'] as String,
  );
}
