class ChecklistTemplateItem {
  const ChecklistTemplateItem({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.sortOrder,
    this.appliesToWorkMode,
    required this.isArchived,
  });

  final String id;

  /// 'onboarding' or 'offboarding'.
  final String type;
  final String title;
  final String? description;
  final int sortOrder;

  /// 'on_site', 'remote', or 'hybrid' — null means every employee regardless
  /// of work mode.
  final String? appliesToWorkMode;
  final bool isArchived;
}
