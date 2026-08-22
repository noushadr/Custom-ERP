import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../employee/presentation/widgets/employee_status_badges.dart';
import '../../domain/entities/payroll_run_status.dart';

class PayrollRunStatusBadge extends StatelessWidget {
  const PayrollRunStatusBadge({super.key, required this.status, this.dense = false});

  final String status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PayrollRunStatus.draft => ('Draft', AppColors.warning),
      PayrollRunStatus.finalized => ('Finalized', AppColors.secondary),
      PayrollRunStatus.paid => ('Paid', AppColors.success),
      _ => (status, AppColors.textSecondary),
    };
    return StatusBadge(label: label, color: color, dense: dense);
  }
}

String formatPayrollRunStatusLabel(String status) => switch (status) {
  PayrollRunStatus.draft => 'Draft',
  PayrollRunStatus.finalized => 'Finalized',
  PayrollRunStatus.paid => 'Paid',
  _ => status,
};

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String formatPayrollRunPeriod(int month, int year) =>
    '${_monthNames[month - 1]} $year';
