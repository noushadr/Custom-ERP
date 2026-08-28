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

/// Formats just the month and day of an ISO date string, e.g. "Oct 03" — for
/// annually-recurring dates (birthdays, work anniversaries) where the year
/// isn't the point, only which day it falls on.
String formatMonthDay(String isoDate) {
  final date = DateTime.parse(isoDate);
  final month = _monthNames[date.month - 1];
  final day = date.day.toString().padLeft(2, '0');
  return '$month $day';
}

/// Formats how long someone has worked here since [isoDate] (their joining
/// date) as e.g. "2 yrs 3 mos", "8 mos", or "Joined this month" — calendar-
/// aware (not a flat 30-day month), relative to today.
String formatTenure(String isoDate) {
  final joined = DateTime.parse(isoDate);
  final now = DateTime.now();

  var years = now.year - joined.year;
  var months = now.month - joined.month;
  if (now.day < joined.day) months -= 1;
  if (months < 0) {
    years -= 1;
    months += 12;
  }
  if (years < 0) return 'Joined today';
  if (years == 0 && months == 0) return 'Joined this month';

  final parts = <String>[
    if (years > 0) '$years ${years == 1 ? 'yr' : 'yrs'}',
    if (months > 0) '$months ${months == 1 ? 'mo' : 'mos'}',
  ];
  return parts.join(' ');
}

// Pakistan Standard Time is a fixed UTC+5 offset with no daylight saving, so
// timestamps are shifted here directly rather than via DateTime.toLocal() —
// which would instead reflect whichever timezone the viewing device is set
// to, not the company's.
const _karachiOffset = Duration(hours: 5);

/// Formats a [DateTime] as a plain date (no time) as e.g. "Oct 03, 2026",
/// always in Asia/Karachi regardless of the viewer's own device timezone —
/// for showing just the day something happened.
String formatDisplayDateOnly(DateTime dateTime) {
  final karachi = (dateTime.isUtc ? dateTime : dateTime.toUtc()).add(
    _karachiOffset,
  );
  final month = _monthNames[karachi.month - 1];
  final day = karachi.day.toString().padLeft(2, '0');
  return '$month $day, ${karachi.year}';
}

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
