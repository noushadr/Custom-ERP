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
