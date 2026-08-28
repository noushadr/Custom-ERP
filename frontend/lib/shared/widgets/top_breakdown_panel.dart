import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'form_section.dart';

/// Counts how often each non-null/non-blank value returned by [selector]
/// appears across [items], sorted most-frequent first and capped to
/// [limit] entries — the data behind every "Top N" breakdown panel in this
/// app (Leads' Top Countries/Services/Lead Sources, Clients & Projects'
/// equivalents).
Map<String, int> computeTopCounts<T>(
  List<T> items,
  String? Function(T) selector, {
  int limit = 5,
}) {
  final counts = <String, int>{};
  for (final item in items) {
    final value = selector(item)?.trim();
    if (value == null || value.isEmpty) continue;
    counts[value] = (counts[value] ?? 0) + 1;
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(sorted.take(limit));
}

/// Lays out [TopBreakdownPanel]s in as many equal-width columns as
/// comfortably fit the available width, wrapping to additional rows for
/// the rest — rather than a fixed single-row-or-stacked split, so this
/// scales correctly whether it's given 3 panels (Leads) or 4+ (Clients &
/// Projects) without a hardcoded panel count.
class TopBreakdownRow extends StatelessWidget {
  const TopBreakdownRow({super.key, required this.panels});

  final List<Widget> panels;

  /// The narrowest a panel can get before `_BreakdownBarRow`'s fixed-width
  /// label/count columns start overflowing its bar — used to decide how
  /// many panels fit per row.
  static const _minPanelWidth = 220.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / _minPanelWidth)
            .floor()
            .clamp(1, panels.length);
        if (columns == 1) {
          return Column(
            children: [
              for (final panel in panels) ...[panel, const SizedBox(height: 12)],
            ],
          );
        }

        final rows = <Widget>[];
        for (var i = 0; i < panels.length; i += columns) {
          final rowPanels = panels.skip(i).take(columns).toList();
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < rowPanels.length; j++) ...[
                  Expanded(child: rowPanels[j]),
                  const SizedBox(width: 12),
                ],
                // Pads a short trailing row so its panels stay the same
                // width as the fully-populated rows above it.
                for (var j = rowPanels.length; j < columns; j++) ...[
                  const Expanded(child: SizedBox.shrink()),
                  const SizedBox(width: 12),
                ],
              ]..removeLast(),
            ),
          );
          if (i + columns < panels.length) rows.add(const SizedBox(height: 12));
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
      },
    );
  }
}

/// A single "Top N" categorical breakdown — one representative hue
/// (magnitude within the panel, not identity across panels, so a single
/// hue is correct rather than a categorical palette).
class TopBreakdownPanel extends StatelessWidget {
  const TopBreakdownPanel({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.counts,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final maxCount = counts.values.isEmpty ? 1 : counts.values.first;
    return FormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (counts.isEmpty)
            Text(
              'No data yet.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            )
          else
            for (final entry in counts.entries) ...[
              _BreakdownBarRow(
                label: entry.key,
                count: entry.value,
                fraction: entry.value / maxCount,
                color: color,
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _BreakdownBarRow extends StatelessWidget {
  const _BreakdownBarRow({
    required this.label,
    required this.count,
    required this.fraction,
    required this.color,
  });

  final String label;
  final int count;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fraction.clamp(0.04, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: Text(
            '$count',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
