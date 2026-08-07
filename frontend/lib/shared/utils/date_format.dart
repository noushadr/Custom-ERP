const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Formats an ISO 'YYYY-MM-DD' date string as e.g. "May 03, 2026".
String formatDisplayDate(String isoDate) {
  final date = DateTime.parse(isoDate);
  final month = _monthNames[date.month - 1];
  final day = date.day.toString().padLeft(2, '0');
  return '$month $day, ${date.year}';
}

/// Formats a [DateTime] with time as e.g. "May 03, 2026, 3:41 PM".
String formatDisplayDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final month = _monthNames[local.month - 1];
  final day = local.day.toString().padLeft(2, '0');
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '$month $day, ${local.year}, $hour12:$minute $period';
}
