import 'package:flutter/material.dart';

class AppNavDestination {
  const AppNavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.comingSoon = false,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Whether this section isn't built yet — shown with a "Coming soon" tag.
  final bool comingSoon;

  /// How many pending items this section has for the current viewer (e.g.
  /// open requests, open tasks) — shown as a small red numbered badge on
  /// the nav icon. Zero means no badge.
  final int badgeCount;
}
