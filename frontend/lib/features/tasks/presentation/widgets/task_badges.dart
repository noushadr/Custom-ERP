import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../employee/presentation/widgets/employee_status_badges.dart';
import '../../domain/entities/task_priority.dart';
import '../../domain/entities/task_status.dart';

class TaskStatusBadge extends StatelessWidget {
  const TaskStatusBadge({super.key, required this.status, this.dense = false});

  final String status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TaskStatus.todo => ('To Do', AppColors.textSecondary),
      TaskStatus.inProgress => ('In Progress', AppColors.secondary),
      TaskStatus.pending => ('Pending', AppColors.warning),
      TaskStatus.completed => ('Completed', AppColors.success),
      TaskStatus.cancelled => ('Cancelled', AppColors.error),
      _ => (status, AppColors.textSecondary),
    };
    return StatusBadge(label: label, color: color, dense: dense);
  }
}

class TaskPriorityBadge extends StatelessWidget {
  const TaskPriorityBadge({
    super.key,
    required this.priority,
    this.dense = false,
  });

  final String priority;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority) {
      TaskPriority.low => ('Low', AppColors.textSecondary),
      TaskPriority.medium => ('Medium', AppColors.secondary),
      TaskPriority.high => ('High', AppColors.warning),
      TaskPriority.urgent => ('Urgent', AppColors.error),
      _ => (priority, AppColors.textSecondary),
    };
    return StatusBadge(
      label: label,
      color: color,
      icon: Icons.flag_outlined,
      dense: dense,
    );
  }
}

/// Human-readable label for a TaskAuditLog `fieldLabel`/status value shown in
/// plain text (e.g. inside an audit log line) rather than as a colored pill.
String formatTaskStatusLabel(String status) => switch (status) {
  TaskStatus.todo => 'To Do',
  TaskStatus.inProgress => 'In Progress',
  TaskStatus.pending => 'Pending',
  TaskStatus.completed => 'Completed',
  TaskStatus.cancelled => 'Cancelled',
  _ => status,
};
