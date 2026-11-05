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

const _segmentColors = [
  AppColors.primary,
  AppColors.secondary,
  AppColors.accentTeal,
  AppColors.success,
  AppColors.warning,
  AppColors.error,
  AppColors.navActive,
];

/// A compact breakdown of [totalAmount] by department: one stacked bar split
/// into each department's share, with a wrapped legend underneath (name,
/// percentage, and PKR amount/count) — used by both the Payroll page's
/// company-wide breakdown and a single Payroll Run's own, so the two stay
/// visually identical while taking a fraction of a row-per-department list.
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

    double percentageOf(DepartmentBreakdownRow row) =>
        totalAmount == 0 ? 0.0 : row.amount / totalAmount * 100;

    return FormSection(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  for (var i = 0; i < rows.length; i++)
                    // A zero-share department still needs a non-zero flex
                    // to be a valid Expanded, but is effectively invisible.
                    Expanded(
                      flex: (percentageOf(rows[i]) * 100).round().clamp(
                        1,
                        10000,
                      ),
                      child: Tooltip(
                        message:
                            '${rows[i].name}: '
                            '${percentageOf(rows[i]).toStringAsFixed(1)}%',
                        child: ColoredBox(
                          color: _segmentColors[i % _segmentColors.length],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              for (var i = 0; i < rows.length; i++)
                _LegendItem(
                  color: _segmentColors[i % _segmentColors.length],
                  row: rows[i],
                  percentage: percentageOf(rows[i]),
                  countLabel: countLabel,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.row,
    required this.percentage,
    required this.countLabel,
  });

  final Color color;
  final DepartmentBreakdownRow row;
  final double percentage;
  final String Function(int count) countLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  row.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            Text(
              'PKR ${formatWholeAmount(row.amount)} · ${countLabel(row.count)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
