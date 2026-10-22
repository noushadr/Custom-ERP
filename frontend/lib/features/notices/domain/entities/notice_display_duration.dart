/// How long a notice stays visible after it is posted. The server turns the
/// chosen preset into an end date (using its own clock); the client only ever
/// picks a preset, never sends a timestamp.
enum NoticeDisplayDuration {
  oneDay('one_day', '1 day'),
  threeDays('three_days', '3 days'),
  oneWeek('one_week', '1 week'),
  twoWeeks('two_weeks', '2 weeks'),
  oneMonth('one_month', '1 month'),
  always('always', 'Always');

  const NoticeDisplayDuration(this.apiValue, this.label);

  /// The value the backend expects for this preset.
  final String apiValue;
  final String label;
}
