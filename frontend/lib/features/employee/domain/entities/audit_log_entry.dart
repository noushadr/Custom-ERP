import '../../../../shared/utils/date_format.dart';

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    this.employeeName,
    required this.actorName,
    required this.fieldLabel,
    required this.oldValue,
    required this.newValue,
    required this.createdAt,
  });

  final String id;
  /// Only populated on the combined company-wide feed.
  final String? employeeName;
  final String actorName;
  final String fieldLabel;
  final String? oldValue;
  final String? newValue;
  final DateTime createdAt;
}

const _dateFieldLabels = {'Joining Date', 'Date of Leaving', 'Date of Birth'};

extension AuditLogEntryDescription on AuditLogEntry {
  /// A human-readable summary of the change, always as "Before → After" so
  /// the changelog never leaves either side to guesswork — a field that was
  /// empty beforehand (or cleared) shows explicitly as "Not set".
  String get describeChange {
    final old = _display(oldValue);
    final current = _display(newValue);
    final hasOld = old != null && old.isNotEmpty;
    final hasNew = current != null && current.isNotEmpty;
    if (!hasOld && !hasNew) return 'No details recorded.';
    return '${hasOld ? old : 'Not set'} → ${hasNew ? current : 'Not set'}';
  }

  String? _display(String? value) {
    if (value == null || value.isEmpty) return value;
    if (!_dateFieldLabels.contains(fieldLabel)) return value;
    if (DateTime.tryParse(value) == null) return value;
    return formatDisplayDate(value);
  }
}
