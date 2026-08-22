import '../../domain/entities/automation.dart';

class AutomationModel extends Automation {
  const AutomationModel({
    required super.type,
    required super.isActive,
    required super.daysBefore,
    required super.updatedByName,
    required super.updatedAt,
  });

  factory AutomationModel.fromJson(Map<String, dynamic> json) =>
      AutomationModel(
        type: json['type'] as String,
        isActive: json['isActive'] as bool,
        daysBefore: json['daysBefore'] as int?,
        updatedByName: json['updatedByName'] as String?,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
