import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../employee/presentation/widgets/employee_status_badges.dart';

class PerformanceReviewStatusBadge extends StatelessWidget {
  const PerformanceReviewStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'pending' => ('Pending', AppColors.warning),
      'completed' => ('Completed', AppColors.primary),
      'finalized' => ('Finalized', AppColors.success),
      _ => (status, AppColors.textSecondary),
    };
    return StatusBadge(label: label, color: color);
  }
}
