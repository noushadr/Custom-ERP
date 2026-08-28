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

/// Lays out a row of [TopBreakdownPanel]s side by side on wide screens,
/// stacked on narrow ones.
class TopBreakdownRow extends StatelessWidget {
  const TopBreakdownRow({super.key, required this.panels});

  final List<Widget> panels;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              for (final panel in panels) ...[panel, const SizedBox(height: 12)],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < panels.length; i++) ...[
              Expanded(child: panels[i]),
              if (i < panels.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
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
