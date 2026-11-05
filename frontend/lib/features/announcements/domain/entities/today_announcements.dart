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

class TodayEmployeeOfMonth {
  const TodayEmployeeOfMonth({
    required this.employeeId,
    required this.fullName,
    this.profilePhotoUrl,
  });

  final String employeeId;
  final String fullName;
  final String? profilePhotoUrl;
}

/// A work-from-home day to tell the viewer about.
class TodayWfhNotice {
  const TodayWfhNotice({required this.personal, this.note});

  /// True when only this viewer was marked, not the whole company.
  final bool personal;
  final String? note;
}

/// Today's and tomorrow's work-from-home day for this viewer, if any.
class TodayWorkFromHome {
  const TodayWorkFromHome({this.today, this.tomorrow});

  final TodayWfhNotice? today;
  final TodayWfhNotice? tomorrow;
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
    required this.employeeOfTheMonth,
    this.workFromHome,
  });

  final List<TodayBirthday> birthdays;
  final List<TodayWorkAnniversary> workAnniversaries;
  final TodayHoliday? holiday;
  final List<TodayNotice> notices;

  /// Non-null for 7 days after HR/Admin approves an Employee of the Month
  /// nomination, then falls away.
  final TodayEmployeeOfMonth? employeeOfTheMonth;

  /// A work-from-home day today or tomorrow, company-wide or just theirs.
  final TodayWorkFromHome? workFromHome;

  bool get isEmpty =>
      birthdays.isEmpty &&
      workAnniversaries.isEmpty &&
      holiday == null &&
      notices.isEmpty &&
      employeeOfTheMonth == null &&
      workFromHome == null;
}
