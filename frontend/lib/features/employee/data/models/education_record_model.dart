import '../../domain/entities/education_record.dart';

class EducationRecordModel extends EducationRecord {
  const EducationRecordModel({
    required super.id,
    required super.degree,
    required super.institution,
    required super.yearCompleted,
    required super.createdAt,
  });

  factory EducationRecordModel.fromJson(Map<String, dynamic> json) =>
      EducationRecordModel(
        id: json['id'] as String,
        degree: json['degree'] as String,
        institution: json['institution'] as String,
        yearCompleted: json['yearCompleted'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
