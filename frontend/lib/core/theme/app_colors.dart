import 'package:flutter/material.dart';

abstract final class AppColors {
  // Surfaces
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color canvasBackground = Color(0xFFEDEEF1);
  static const Color fieldFill = Color(0xFFE9EBEF);

  // Left nav — a shade deeper than the canvas so it reads as a distinct,
  // simple panel rather than blending into the page.
  static const Color sidebarBackground = Color(0xFFE2E5EA);

  // Brand
  static const Color primary = Color(0xFF00D5EE);
  static const Color primarySoft = Color(0xFFE3FBFD);

  // Text
  static const Color textPrimary = Color(0xFF14181F);
  static const Color textSecondary = Color(0xFF59606B);

  // Borders
  static const Color border = Color(0xFFD6D9DE);
  static const Color borderSubtle = Color(0xFFE3E5E9);

  // Status
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
}
