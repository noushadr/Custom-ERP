class EmployeeRequest {
  const EmployeeRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.requesterPhotoUrl,
    required this.subject,
    required this.description,
    this.type,
    required this.kind,
    required this.status,
    this.managerDecisionAt,
    this.managerDecisionByName,
    this.hrDecisionAt,
    this.hrDecisionByName,
    this.rejectionReason,
    required this.createdAt,
  });

  final String id;
  final String requesterId;
  final String requesterName;
  final String? requesterPhotoUrl;
  final String subject;
  final String description;
  final String? type;

  /// `general` or `profile_change` — a `profile_change` request skips
  /// manager approval entirely and is created straight at
  /// `manager_approved`, awaiting HR/Admin only.
  final String kind;

  /// One of: `submitted`, `manager_approved`, `completed`, `rejected`.
  final String status;
  final DateTime? managerDecisionAt;
  final String? managerDecisionByName;
  final DateTime? hrDecisionAt;
  final String? hrDecisionByName;
  final String? rejectionReason;
  final DateTime createdAt;
}
