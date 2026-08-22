/// Raw values matching the backend's ClientHealthStatus enum.
class ClientHealthStatus {
  static const healthy = 'healthy';
  static const attentionRequired = 'attention_required';
  static const atRisk = 'at_risk';

  static const values = [healthy, attentionRequired, atRisk];
}
