/// One row per AutomationType — a fixed catalog, admin-toggleable with
/// configurable parameters, never created/deleted.
class Automation {
  const Automation({
    required this.type,
    required this.isActive,
    required this.daysBefore,
    required this.updatedByName,
    required this.updatedAt,
  });

  /// One of AutomationType's values.
  final String type;
  final bool isActive;

  /// Only meaningful for the two reminder types — null for annual leave
  /// reset, whose trigger is intrinsic to the leave year rollover.
  final int? daysBefore;
  final String? updatedByName;
  final DateTime updatedAt;
}
