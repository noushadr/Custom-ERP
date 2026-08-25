import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A compact stat tile: a large value over a label, on a background softly
/// tinted with [color]. Used on the Dashboard and anywhere else a quick
/// count/metric needs to be shown.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
    this.secondaryValue,
    this.valueFontSize,
    this.labelFirst = false,
  });

  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  /// An optional smaller line shown right below [value] — e.g. an
  /// approximate USD figure below a PKR headline amount.
  final String? secondaryValue;

  /// Overrides the default `headlineSmall` size — for a caller whose
  /// [value] strings run unusually long (e.g. a full currency figure with
  /// a bracketed conversion) and would otherwise crowd the tile.
  final double? valueFontSize;

  /// Puts [label] first as a prominent heading above [value], instead of
  /// the default small caption below it — for a caller whose tiles read
  /// better named-then-valued (e.g. "Total Revenue" above the figure)
  /// rather than value-then-caption.
  final bool labelFirst;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: labelFirst
          ? Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            )
          : Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
    );
    final valueText = Text(
      value,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: valueFontSize,
      ),
    );

    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 10),
          ],
          if (labelFirst) ...[labelText, const SizedBox(height: 4)],
          valueText,
          if (secondaryValue != null) ...[
            const SizedBox(height: 1),
            Text(
              secondaryValue!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (!labelFirst) ...[const SizedBox(height: 2), labelText],
        ],
      ),
    );
  }
}
