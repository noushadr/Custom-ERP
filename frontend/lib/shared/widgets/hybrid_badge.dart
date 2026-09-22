import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A small pill flagging that more than one team/department is involved —
/// shown on a project's department picker (editor) and its department list
/// (detail page) once more than one is selected/assigned.
class HybridBadge extends StatelessWidget {
  const HybridBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Hybrid',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
