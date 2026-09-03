import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../utils/currency_format.dart';
import 'form_section.dart';

/// One row's worth of data for [DepartmentBreakdownSection] — a department
/// (or a pseudo-department bucket like "Unassigned"/"Freelancers") and its
/// share of some PKR total.
class DepartmentBreakdownRow {
  const DepartmentBreakdownRow({
    required this.name,
    required this.amount,
    required this.count,
  });

  final String name;
  final double amount;
  final int count;
}

/// A titled list of [DepartmentBreakdownRow]s, each showing its percentage
/// of [totalAmount] as the prominent figure and the PKR amount/count as a
/// secondary line — used both by the HR/Admin Dashboard's company-wide
/// payroll breakdown and a single Payroll Run's own breakdown, so the two
/// stay visually and behaviorally identical.
class DepartmentBreakdownSection extends StatelessWidget {
  const DepartmentBreakdownSection({
    super.key,
    required this.title,
    required this.rows,
    required this.totalAmount,
    required this.countLabel,
  });

  final String title;
  final List<DepartmentBreakdownRow> rows;
  final double totalAmount;

  /// Builds the trailing count phrase for a row, e.g. `(n) => '$n
  /// employees'`.
  final String Function(int count) countLabel;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    return FormSection(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _DepartmentBreakdownRowTile(
              row: rows[i],
              totalAmount: totalAmount,
              countLabel: countLabel,
            ),
            if (i < rows.length - 1)
              const Divider(height: 16, color: AppColors.borderSubtle),
          ],
        ],
      ),
    );
  }
}

class _DepartmentBreakdownRowTile extends StatelessWidget {
  const _DepartmentBreakdownRowTile({
    required this.row,
    required this.totalAmount,
    required this.countLabel,
  });

  final DepartmentBreakdownRow row;
  final double totalAmount;
  final String Function(int count) countLabel;

  @override
  Widget build(BuildContext context) {
    final percentage = totalAmount == 0 ? 0.0 : row.amount / totalAmount * 100;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            row.name,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${percentage.toStringAsFixed(1)}% of payroll',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Text(
              'PKR ${formatWholeAmount(row.amount)} · ${countLabel(row.count)}',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}
