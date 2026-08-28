import '../../domain/entities/client_health_summary.dart';

class ClientHealthSummaryModel extends ClientHealthSummary {
  const ClientHealthSummaryModel({
    required super.healthyCount,
    required super.attentionRequiredCount,
    required super.atRiskCount,
  });

  factory ClientHealthSummaryModel.fromJson(Map<String, dynamic> json) =>
      ClientHealthSummaryModel(
        healthyCount: json['healthyCount'] as int,
        attentionRequiredCount: json['attentionRequiredCount'] as int,
        atRiskCount: json['atRiskCount'] as int,
      );
}
