import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'form_section.dart';

const _kMonthAbbreviations = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// A titled, horizontally-scrollable monthly bar chart — hand-rolled from
/// plain widgets (no charting package), matching this app's established
/// convention for every other chart (Leads' own monthly chart, Financial
/// Reports' bar charts). [counts] is keyed by `'YYYY-MM'`; bars render
/// oldest-to-newest, left-to-right.
class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({
    super.key,
    required this.title,
    required this.counts,
    this.color = AppColors.primary,
    this.unitLabel = 'item',
    this.unitLabelPlural,
  });

  final String title;

  /// Keyed by `'YYYY-MM'` (e.g. `'2026-09'`).
  final Map<String, int> counts;
  final Color color;

  /// Singular noun used in each bar's tooltip, e.g. `'hire'` for "3 hires".
  final String unitLabel;

  /// Defaults to [unitLabel] + 's' when not given.
  final String? unitLabelPlural;

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) return const SizedBox.shrink();

    final months = counts.keys.toList()..sort();
    final maxCount = counts.values.reduce((a, b) => a > b ? a : b);
    final plural = unitLabelPlural ?? '${unitLabel}s';

    return FormSection(
      title: title,
      child: SizedBox(
        height: 178,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final month in months)
                _MonthBar(
                  label: _formatMonthLabel(month),
                  count: counts[month]!,
                  fraction: maxCount == 0 ? 0 : counts[month]! / maxCount,
                  color: color,
                  unitLabel: unitLabel,
                  unitLabelPlural: plural,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatMonthLabel(String monthKey) {
    final parts = monthKey.split('-');
    final year = parts[0];
    final monthIndex = int.parse(parts[1]) - 1;
    return '${_kMonthAbbreviations[monthIndex]}\n$year';
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.label,
    required this.count,
    required this.fraction,
    required this.color,
    required this.unitLabel,
    required this.unitLabelPlural,
  });

  final String label;
  final int count;
  final double fraction;
  final Color color;
  final String unitLabel;
  final String unitLabelPlural;

  static const _maxBarHeight = 100.0;

  @override
  Widget build(BuildContext context) {
    final unit = count == 1 ? unitLabel : unitLabelPlural;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Tooltip(
        message: '${label.replaceAll('\n', ' ')}: $count $unit',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // A direct count label above each bar — visible without
            // hovering; the tooltip above still carries the full sentence.
            Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: _maxBarHeight,
              width: 26,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: (_maxBarHeight * fraction).clamp(4.0, _maxBarHeight),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 42,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
