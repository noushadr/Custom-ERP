import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

const _employmentTypeLabels = {
  'full_time': 'Full-time',
  'part_time': 'Part-time',
  'contract': 'Contract',
  'intern': 'Intern',
};

/// Formats the raw `employmentType` enum value for display, e.g. `full_time`
/// becomes "Full-time". Falls back to the raw value for anything unmapped.
String formatEmploymentType(String employmentType) =>
    _employmentTypeLabels[employmentType] ?? employmentType;

/// A small icon + label chip, e.g. for showing an employee code, email, or
/// joining date inline.
class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.icon, required this.label, this.maxWidth});

  final IconData icon;
  final String label;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class EmploymentStatusBadge extends StatelessWidget {
  const EmploymentStatusBadge({
    super.key,
    required this.status,
    this.dense = false,
  });

  final String status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('Active', AppColors.success),
      'on_leave' => ('On Leave', AppColors.warning),
      'notice_period' => ('Notice Period', AppColors.warning),
      'resigned' => ('Resigned', AppColors.error),
      'terminated' => ('Terminated', AppColors.error),
      _ => (status, AppColors.textSecondary),
    };

    return StatusBadge(label: label, color: color, dense: dense);
  }
}

class WorkModeBadge extends StatelessWidget {
  const WorkModeBadge({
    super.key,
    required this.workMode,
    this.dense = false,
  });

  final String workMode;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (workMode) {
      'remote' => ('Remote', Icons.home_outlined),
      'on_site' => ('On-site', Icons.apartment_outlined),
      'hybrid' => ('Hybrid', Icons.sync_alt_outlined),
      _ => (workMode, Icons.apartment_outlined),
    };

    return StatusBadge(
      label: label,
      color: AppColors.textSecondary,
      icon: icon,
      dense: dense,
    );
  }
}

/// A small colored pill — the base building block for the status badges
/// above. Named to avoid clashing with Flutter's own [Badge] widget.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.dense = false,
  });

  final String label;
  final Color color;
  final IconData? icon;

  /// A slightly smaller rendering — smaller padding/icon/font — for
  /// contexts like the employee directory card where many badges and chips
  /// need to fit comfortably without dominating the row.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 11,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: dense ? 10.5 : null,
            ),
          ),
        ],
      ),
    );
  }
}
