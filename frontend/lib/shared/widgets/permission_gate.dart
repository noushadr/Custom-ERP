import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Shown by an Admin Business Management page when the viewer lacks the
/// permission it requires — a second line of defense alongside the
/// backend's `@Permissions()` guard and `main.dart`'s nav-visibility
/// filtering.
///
/// Each such page checks `authUser.hasPermission(...)` at the very top of
/// its own `build()`, before watching any of its own data providers, and
/// returns this instead. Without that early check, the page (and the
/// providers it watches) would still be built for every authenticated
/// user — this app's `IndexedStack`-based nav keeps every section mounted
/// regardless of which tab is visible, so a hidden nav item alone doesn't
/// stop the page underneath it from being constructed and fetching data
/// the moment any user logs in.
class AccessDeniedView extends StatelessWidget {
  const AccessDeniedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 32,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              "You don't have permission to view this page.",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
