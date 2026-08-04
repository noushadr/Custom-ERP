import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Slim copyright strip shown at the bottom of the login page and every
/// page inside the authenticated shell.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        '© 2026 Zera Creative LLC, WY USA.',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
