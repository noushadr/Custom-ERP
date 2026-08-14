const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats an ISO 'YYYY-MM-DD' date string as e.g. "Oct 03, 2026".
String formatDisplayDate(String isoDate) {
  final date = DateTime.parse(isoDate);
  final month = _monthNames[date.month - 1];
  final day = date.day.toString().padLeft(2, '0');
  return '$month $day, ${date.year}';
}

// Pakistan Standard Time is a fixed UTC+5 offset with no daylight saving, so
// timestamps are shifted here directly rather than via DateTime.toLocal() —
// which would instead reflect whichever timezone the viewing device is set
// to, not the company's.
const _karachiOffset = Duration(hours: 5);

/// Formats a [DateTime] with time as e.g. "Oct 03, 2026, 3:41 PM", always in
/// Asia/Karachi regardless of the viewer's own device timezone.
String formatDisplayDateTime(DateTime dateTime) {
  final karachi = (dateTime.isUtc ? dateTime : dateTime.toUtc()).add(
    _karachiOffset,
  );
  final month = _monthNames[karachi.month - 1];
  final day = karachi.day.toString().padLeft(2, '0');
  final hour12 = karachi.hour % 12 == 0 ? 12 : karachi.hour % 12;
  final minute = karachi.minute.toString().padLeft(2, '0');
  final period = karachi.hour < 12 ? 'AM' : 'PM';
  return '$month $day, ${karachi.year}, $hour12:$minute $period';
}

/// Formats how long ago [dateTime] was: minutes/hours for anything under a
/// day old, then whole days beyond that (e.g. "5 hours ago", "3 days ago").
/// Timezone-agnostic — both ends of the difference are absolute instants.
String formatRelativeTime(DateTime dateTime) {
  final then = dateTime.isUtc ? dateTime : dateTime.toUtc();
  final diff = DateTime.now().toUtc().difference(then);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) {
    final minutes = diff.inMinutes;
    return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
  }
  if (diff.inHours < 24) {
    final hours = diff.inHours;
    return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
  }
  final days = diff.inDays;
  return '$days ${days == 1 ? 'day' : 'days'} ago';
}
