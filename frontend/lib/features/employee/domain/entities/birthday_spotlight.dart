import 'upcoming_birthday.dart';

/// Every active employee's birthday falling in the current calendar month
/// or the next one — grouped by month, not a single closest-past/closest-
/// upcoming pair, since several people can share a month.
class BirthdaySpotlight {
  const BirthdaySpotlight({required this.thisMonth, required this.nextMonth});

  final List<UpcomingBirthday> thisMonth;
  final List<UpcomingBirthday> nextMonth;
}
