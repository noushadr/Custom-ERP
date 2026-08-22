class EmployeeChecklistItem {
  const EmployeeChecklistItem({
    required this.id,
    required this.employeeId,
    this.templateItemId,
    required this.type,
    required this.title,
    required this.sortOrder,
    required this.isCompleted,
    this.completedAt,
    this.completedByName,
    this.note,
  });

  final String id;
  final String employeeId;
  final String? templateItemId;

  /// 'onboarding' or 'offboarding'.
  final String type;
  final String title;
  final int sortOrder;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? completedByName;
  final String? note;
}
