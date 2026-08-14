import 'audit_log_entry.dart';

/// One page of the combined, searchable company-wide audit log.
class PaginatedAuditLog {
  const PaginatedAuditLog({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<AuditLogEntry> items;
  final int total;
  final int page;
  final int limit;

  int get totalPages => total == 0 ? 1 : (total / limit).ceil();
}
