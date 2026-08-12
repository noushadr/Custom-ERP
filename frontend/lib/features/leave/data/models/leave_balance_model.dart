import '../../domain/entities/leave_balance.dart';

class LeaveBalanceModel extends LeaveBalance {
  const LeaveBalanceModel({
    required super.leaveTypeId,
    required super.leaveTypeName,
    super.colorHex,
    required super.year,
    required super.allocated,
    required super.used,
    required super.remaining,
  });

  factory LeaveBalanceModel.fromJson(Map<String, dynamic> json) =>
      LeaveBalanceModel(
        leaveTypeId: json['leaveTypeId'] as String,
        leaveTypeName: json['leaveTypeName'] as String,
        colorHex: json['colorHex'] as String?,
        year: json['year'] as int,
        allocated: (json['allocated'] as num).toDouble(),
        used: (json['used'] as num).toDouble(),
        remaining: (json['remaining'] as num).toDouble(),
      );
}
