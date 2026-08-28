import '../../domain/entities/checklist_template_item.dart';

class ChecklistTemplateItemModel extends ChecklistTemplateItem {
  const ChecklistTemplateItemModel({
    required super.id,
    required super.type,
    required super.title,
    super.description,
    required super.sortOrder,
    super.appliesToWorkMode,
    required super.isArchived,
  });

  factory ChecklistTemplateItemModel.fromJson(Map<String, dynamic> json) =>
      ChecklistTemplateItemModel(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        sortOrder: json['sortOrder'] as int,
        appliesToWorkMode: json['appliesToWorkMode'] as String?,
        isArchived: json['isArchived'] as bool,
      );
}
