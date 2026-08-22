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
  });

  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  /// An optional smaller line shown right below [value] — e.g. an
  /// approximate USD figure below a PKR headline amount.
  final String? secondaryValue;

  @override
  Widget build(BuildContext context) {
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
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (secondaryValue != null) ...[
            const SizedBox(height: 1),
            Text(
              secondaryValue!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
