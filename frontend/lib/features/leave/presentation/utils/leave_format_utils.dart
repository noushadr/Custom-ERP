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

/// Formats a [DateTime] as an ISO 'YYYY-MM-DD' string.
String isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Counts working days (Mon–Fri, excluding [holidayDates]) in the inclusive
/// range from [start] to [end] — mirrors the backend's authoritative
/// `LeaveService.countWorkingDays`, so the live preview shown while picking
/// dates matches what the server will actually charge against the balance.
int countWorkingDays(DateTime start, DateTime end, Set<String> holidayDates) {
  var cursor = DateTime.utc(start.year, start.month, start.day);
  final last = DateTime.utc(end.year, end.month, end.day);
  var count = 0;
  while (!cursor.isAfter(last)) {
    final isWeekend =
        cursor.weekday == DateTime.saturday || cursor.weekday == DateTime.sunday;
    if (!isWeekend && !holidayDates.contains(isoDate(cursor))) count++;
    cursor = cursor.add(const Duration(days: 1));
  }
  return count;
}
