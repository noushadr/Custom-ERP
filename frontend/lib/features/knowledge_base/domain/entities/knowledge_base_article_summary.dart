import 'knowledge_base_content_kind.dart';
import 'knowledge_base_file_info.dart';
import 'knowledge_base_visibility.dart';

/// A list-row shape — title, author, and dates only, no content or
/// targeting detail. Used for the list page's Recently Published/Recently
/// Updated/All Articles sections.
class KnowledgeBaseArticleSummary {
  const KnowledgeBaseArticleSummary({
    required this.id,
    required this.title,
    required this.visibilityType,
    required this.authorName,
    required this.lastEditedByName,
    required this.versionNumber,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.contentKind = KnowledgeBaseContentKind.richText,
    this.files = const [],
    this.targetRoleNames = const [],
    this.targetDepartmentNames = const [],
  });

  final String id;
  final String title;

  /// One of KnowledgeBaseVisibility's values.
  final String visibilityType;
  final String authorName;
  final String lastEditedByName;
  final int versionNumber;
  final bool isArchived;

  /// Doubles as "publication date".
  final DateTime createdAt;

  /// Doubles as "last updated date".
  final DateTime updatedAt;

  /// One of KnowledgeBaseContentKind's values.
  final String contentKind;

  /// The uploaded files, in order — empty for a written article.
  final List<KnowledgeBaseFileInfo> files;

  /// Who can read it, by name (empty when the targeting doesn't use them).
  final List<String> targetRoleNames;
  final List<String> targetDepartmentNames;

  bool get isFile => contentKind == KnowledgeBaseContentKind.file;

  /// A short description of the audience for list rows: Everyone, specific
  /// departments, specific roles, or both ("Hybrid").
  String get audienceLabel {
    final roles = targetRoleNames.join(', ');
    final departments = targetDepartmentNames.join(', ');
    switch (visibilityType) {
      case KnowledgeBaseVisibility.roles:
        return roles.isEmpty ? 'Specific roles' : 'Roles: $roles';
      case KnowledgeBaseVisibility.departments:
        return departments.isEmpty
            ? 'Specific departments'
            : 'Departments: $departments';
      case KnowledgeBaseVisibility.rolesAndDepartments:
        return 'Hybrid — '
            '${roles.isEmpty ? 'roles' : 'Roles: $roles'} + '
            '${departments.isEmpty ? 'departments' : 'Departments: $departments'}';
      default:
        return 'Everyone';
    }
  }
}
