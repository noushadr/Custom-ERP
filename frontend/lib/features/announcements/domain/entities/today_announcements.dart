class TodayBirthday {
  const TodayBirthday({
    required this.employeeId,
    required this.fullName,
    this.profilePhotoUrl,
  });

  final String employeeId;
  final String fullName;
  final String? profilePhotoUrl;
}

class TodayWorkAnniversary {
  const TodayWorkAnniversary({
    required this.employeeId,
    required this.fullName,
    required this.yearsOfService,
    this.profilePhotoUrl,
  });

  final String employeeId;
  final String fullName;
  final int yearsOfService;
  final String? profilePhotoUrl;
}

class TodayHoliday {
  const TodayHoliday({required this.name, required this.date});

  final String name;

  /// ISO 'YYYY-MM-DD'.
  final String date;
}

class TodayNotice {
  const TodayNotice({
    required this.id,
    required this.title,
    required this.authorName,
  });

  final String id;
  final String title;
  final String authorName;
}

/// Same-day-only slice of birthdays/anniversaries/holiday/notices, powering
/// the top-bar announcement banner — everyone sees this, unlike the HR-only
/// "Celebrations" feed in the notification bell.
class TodayAnnouncements {
  const TodayAnnouncements({
    required this.birthdays,
    required this.workAnniversaries,
    required this.holiday,
    required this.notices,
  });

  final List<TodayBirthday> birthdays;
  final List<TodayWorkAnniversary> workAnniversaries;
  final TodayHoliday? holiday;
  final List<TodayNotice> notices;

  bool get isEmpty =>
      birthdays.isEmpty &&
      workAnniversaries.isEmpty &&
      holiday == null &&
      notices.isEmpty;
}
