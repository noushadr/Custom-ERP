import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../employee/presentation/widgets/employee_status_badges.dart';
import '../../domain/entities/project_status.dart';
import '../../domain/entities/project_type.dart';

class ProjectStatusBadge extends StatelessWidget {
  const ProjectStatusBadge({super.key, required this.status, this.dense = false});

  final String status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ProjectStatus.active => ('Active', AppColors.success),
      ProjectStatus.onHold => ('On Hold', AppColors.warning),
      ProjectStatus.completed => ('Completed', AppColors.textSecondary),
      ProjectStatus.cancelled => ('Cancelled', AppColors.error),
      _ => (status, AppColors.textSecondary),
    };
    return StatusBadge(label: label, color: color, dense: dense);
  }
}

class ProjectTypeBadge extends StatelessWidget {
  const ProjectTypeBadge({super.key, required this.type, this.dense = false});

  final String type;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (type) {
      ProjectType.retainer => ('Retainer', Icons.event_repeat_outlined),
      ProjectType.oneTime => ('One-time', Icons.flash_on_outlined),
      _ => (type, Icons.work_outline),
    };
    return StatusBadge(
      label: label,
      color: AppColors.secondary,
      icon: icon,
      dense: dense,
    );
  }
}

String formatProjectStatusLabel(String status) => switch (status) {
  ProjectStatus.active => 'Active',
  ProjectStatus.onHold => 'On Hold',
  ProjectStatus.completed => 'Completed',
  ProjectStatus.cancelled => 'Cancelled',
  _ => status,
};

String formatProjectTypeLabel(String type) => switch (type) {
  ProjectType.retainer => 'Retainer',
  ProjectType.oneTime => 'One-time',
  _ => type,
};
