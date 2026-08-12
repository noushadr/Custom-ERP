import '../../domain/entities/leave_type.dart';

class LeaveTypeModel extends LeaveType {
  const LeaveTypeModel({
    required super.id,
    required super.name,
    required super.annualAllowanceDays,
    super.carryForwardLimitDays,
    super.colorHex,
    required super.isArchived,
  });

  factory LeaveTypeModel.fromJson(Map<String, dynamic> json) => LeaveTypeModel(
    id: json['id'] as String,
    name: json['name'] as String,
    annualAllowanceDays: double.parse(json['annualAllowanceDays'] as String),
    carryForwardLimitDays: json['carryForwardLimitDays'] == null
        ? null
        : double.parse(json['carryForwardLimitDays'] as String),
    colorHex: json['colorHex'] as String?,
    isArchived: json['isArchived'] as bool,
  );
}
