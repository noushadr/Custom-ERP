import 'package:flutter/material.dart';

abstract final class AppColors {
  // Surfaces
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color canvasBackground = Color(0xFFF5F4FB);
  static const Color fieldFill = Color(0xFFF1F0F9);

  // Left nav — white like the content area; separated from the canvas by a
  // hairline border rather than a flat fill, so it reads as part of the same
  // modern surface language instead of a boxed-off panel.
  static const Color sidebarBackground = Color(0xFFFFFFFF);

  // Brand — violet primary with blue/teal as secondary accents, used
  // together the way the reference dashboard mixes tones across stat tiles,
  // charts, and progress rings.
  static const Color primary = Color(0xFF6C5DD3);
  static const Color primarySoft = Color(0xFFEDEBFC);
  static const Color secondary = Color(0xFF4F8EF7);
  static const Color secondarySoft = Color(0xFFE8F0FE);
  // The original Zera cyan, kept as a tertiary accent (chart lines, a third
  // progress ring) rather than dropped outright.
  static const Color accentTeal = Color(0xFF00D5EE);
  static const Color accentTealSoft = Color(0xFFE3FBFD);
  // Near-black, used for high-contrast tiles and the active nav pill.
  static const Color navActive = Color(0xFF181425);

  // Text
  static const Color textPrimary = Color(0xFF14181F);
  static const Color textSecondary = Color(0xFF625F73);

  // Borders
  static const Color border = Color(0xFFE3E1F0);
  static const Color borderSubtle = Color(0xFFEEECF7);

  // Status
  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFE7F7EE);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFCF1E3);
  static const Color error = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFBE9E9);
}
