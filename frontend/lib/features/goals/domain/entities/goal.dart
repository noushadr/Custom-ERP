class Goal {
  const Goal({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    this.employeePhotoUrl,
    this.departmentId,
    this.departmentName,
    required this.title,
    this.description,
    required this.achievementPercentage,
    required this.createdByName,
    required this.createdAt,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final String? employeePhotoUrl;
  final String? departmentId;
  final String? departmentName;
  final String title;
  final String? description;

  /// 0-100 — set only by Admin/HR (via the edit dialog's percentage field);
  /// a Team Lead or the employee themselves see it read-only.
  final int achievementPercentage;

  /// Snapshot of whoever set this goal — Admin/HR or the employee's own
  /// Team Lead.
  final String createdByName;
  final DateTime createdAt;
}
