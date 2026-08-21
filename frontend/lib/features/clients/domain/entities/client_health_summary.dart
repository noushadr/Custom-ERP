class ClientHealthSummary {
  const ClientHealthSummary({
    required this.healthyCount,
    required this.attentionRequiredCount,
    required this.atRiskCount,
  });

  final int healthyCount;
  final int attentionRequiredCount;
  final int atRiskCount;
}
