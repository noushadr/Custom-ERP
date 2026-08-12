import 'package:flutter/material.dart';

/// Formats a day count without a trailing ".0" for whole numbers.
String formatLeaveDays(double days) =>
    days == days.roundToDouble() ? days.toInt().toString() : days.toStringAsFixed(1);

Color? parseLeaveColor(String? hex) {
  if (hex == null) return null;
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return null;
  return Color(cleaned.length == 6 ? 0xFF000000 | value : value);
}
