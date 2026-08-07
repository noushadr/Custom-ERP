import '../../domain/entities/salary_record.dart';

class SalaryRecordModel extends SalaryRecord {
  const SalaryRecordModel({
    required super.id,
    required super.amount,
    required super.effectiveDate,
    super.note,
    required super.createdAt,
  });

  factory SalaryRecordModel.fromJson(Map<String, dynamic> json) =>
      SalaryRecordModel(
        id: json['id'] as String,
        amount: double.parse(json['amount'] as String),
        effectiveDate: json['effectiveDate'] as String,
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
