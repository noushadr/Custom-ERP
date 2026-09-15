import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'form_section.dart';

/// Fixed hue rotation for categorical slices, cycling if a breakdown has
/// more categories than colors — same reasoning [TopBreakdownPanel] gives
/// for its own single-hue-per-panel choice, just extended to per-slice here
/// since every slice needs to be told apart from its neighbors at once.
const _kSlicePalette = <Color>[
  AppColors.primary,
  AppColors.secondary,
  AppColors.accentTeal,
  AppColors.success,
  AppColors.warning,
  AppColors.error,
  AppColors.navActive,
];

/// A titled donut chart for a categorical count breakdown (e.g. employees
/// by department) — hand-rolled via [CustomPainter], matching this app's
/// established no-charting-package-dependency convention (see
/// `MonthlyBarChart`, Financial Reports' own charts). Pairs the ring with a
/// swatch+label+count+percentage legend; [counts] is drawn/listed in
/// whatever order it's given — this widget doesn't re-sort.
class PieChartPanel extends StatelessWidget {
  const PieChartPanel({
    super.key,
    required this.title,
    required this.icon,
    required this.counts,
    this.compact = false,
  });

  final String title;
  final IconData icon;
  final Map<String, int> counts;

  /// Roughly half-size — smaller ring, thinner stroke, smaller text — for a
  /// caller placing this in a narrow sidebar column rather than a full-width
  /// section.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (sum, value) => sum + value);
    final chartSize = compact ? 70.0 : 140.0;
    final ringWidth = compact ? 11.0 : 22.0;

    return FormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: compact ? 14 : 18,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: compact ? 6 : 8),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: compact
                      ? Theme.of(context).textTheme.bodySmall
                      : Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 16),
          if (counts.isEmpty || total == 0)
            Text(
              'No data yet.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final chart = SizedBox(
                  width: chartSize,
                  height: chartSize,
                  child: CustomPaint(
                    painter: _PieChartPainter(
                      counts: counts,
                      total: total,
                      ringWidth: ringWidth,
                    ),
                    child: Center(
                      child: compact
                          ? Text(
                              '$total',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$total',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  'total',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                    ),
                  ),
                );
                final legend = _PieChartLegend(
                  counts: counts,
                  total: total,
                  compact: compact,
                );

                // Side-by-side once there's room for the ring plus a
                // legend column; stacked otherwise (a narrow sidebar, a
                // mobile layout).
                if (constraints.maxWidth < (compact ? 260 : 420)) {
                  return Column(
                    children: [
                      Center(child: chart),
                      SizedBox(height: compact ? 10 : 16),
                      legend,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    chart,
                    SizedBox(width: compact ? 14 : 24),
                    Expanded(child: legend),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PieChartLegend extends StatelessWidget {
  const _PieChartLegend({
    required this.counts,
    required this.total,
    required this.compact,
  });

  final Map<String, int> counts;
  final int total;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final entries = counts.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          _LegendRow(
            color: _kSlicePalette[i % _kSlicePalette.length],
            label: entries[i].key,
            count: entries[i].value,
            percentage: total == 0 ? 0 : entries[i].value / total * 100,
            compact: compact,
          ),
          SizedBox(height: compact ? 4 : 8),
        ],
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.percentage,
    required this.compact,
  });

  final Color color;
  final String label;
  final int count;
  final double percentage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textStyle = compact
        ? Theme.of(context).textTheme.labelSmall
        : Theme.of(context).textTheme.bodySmall;

    return Row(
      children: [
        Container(
          width: compact ? 6 : 10,
          height: compact ? 6 : 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: compact ? 5 : 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
        SizedBox(width: compact ? 4 : 8),
        Text(
          '$count',
          style: textStyle?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(width: compact ? 4 : 6),
        SizedBox(
          width: compact ? 30 : 38,
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style:
                (compact
                        ? Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                          )
                        : Theme.of(context).textTheme.labelSmall)
                    ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({
    required this.counts,
    required this.total,
    required this.ringWidth,
  });

  final Map<String, int> counts;
  final int total;
  final double ringWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final diameter = size.shortestSide - ringWidth;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: diameter,
      height: diameter,
    );

    var startAngle = -math.pi / 2;
    var i = 0;
    for (final value in counts.values) {
      final sweepAngle = total == 0 ? 0.0 : (value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = _kSlicePalette[i % _kSlicePalette.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) =>
      oldDelegate.counts != counts ||
      oldDelegate.total != total ||
      oldDelegate.ringWidth != ringWidth;
}
