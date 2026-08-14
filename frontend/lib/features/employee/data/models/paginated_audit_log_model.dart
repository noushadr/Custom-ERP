import '../../domain/entities/paginated_audit_log.dart';
import 'audit_log_entry_model.dart';

class PaginatedAuditLogModel extends PaginatedAuditLog {
  const PaginatedAuditLogModel({
    required super.items,
    required super.total,
    required super.page,
    required super.limit,
  });

  factory PaginatedAuditLogModel.fromJson(Map<String, dynamic> json) =>
      PaginatedAuditLogModel(
        items: (json['items'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(AuditLogEntryModel.fromJson)
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        limit: json['limit'] as int,
      );
}
