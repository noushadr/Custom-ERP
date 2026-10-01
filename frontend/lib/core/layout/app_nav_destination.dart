import 'package:flutter/material.dart';

class AppNavDestination {
  const AppNavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.comingSoon = false,
    this.badgeCount = 0,
    this.displayLabel,
  });

  /// Stable identity used everywhere this app looks a destination up by
  /// name — switch-cases, visibility sets, badge-count maps, `_goToDestination`
  /// calls. Never shown to the user when [displayLabel] is set.
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Whether this section isn't built yet — shown with a "Coming soon" tag.
  final bool comingSoon;

  /// How many pending items this section has for the current viewer (e.g.
  /// open requests, open tasks) — shown as a small red numbered badge on
  /// the nav icon. Zero means no badge.
  final int badgeCount;

  /// Text actually rendered in the nav/page title, when it needs to differ
  /// from [label] — e.g. the non-admin "User Dashboard" destination reads
  /// just "Dashboard" to the employee viewing it, while every internal
  /// lookup still keys off the unique `'User Dashboard'` label so it never
  /// collides with the Super Admin's own, separate `'Dashboard'` entry.
  final String? displayLabel;

  String get visibleLabel => displayLabel ?? label;
}
