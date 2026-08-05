import 'package:flutter/material.dart';

class AppNavDestination {
  const AppNavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.comingSoon = false,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Whether this section isn't built yet — shown with a "Coming soon" tag.
  final bool comingSoon;
}
