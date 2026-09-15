import 'upcoming_birthday.dart';

/// The single most-recently-passed and single soonest-upcoming birthday
/// among active employees — either side is null when no active employee
/// has a date of birth on file in that direction.
class BirthdaySpotlight {
  const BirthdaySpotlight({this.last, this.upcoming});

  final UpcomingBirthday? last;
  final UpcomingBirthday? upcoming;
}
