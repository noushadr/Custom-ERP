import '../../domain/entities/today_announcements.dart';

class TodayAnnouncementsModel extends TodayAnnouncements {
  const TodayAnnouncementsModel({
    required super.birthdays,
    required super.workAnniversaries,
    required super.holiday,
    required super.notices,
  });

  factory TodayAnnouncementsModel.fromJson(Map<String, dynamic> json) {
    final holidayJson = json['holiday'] as Map<String, dynamic>?;
    return TodayAnnouncementsModel(
      birthdays: (json['birthdays'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(
            (b) => TodayBirthday(
              employeeId: b['employeeId'] as String,
              fullName: b['fullName'] as String,
              profilePhotoUrl: b['profilePhotoUrl'] as String?,
            ),
          )
          .toList(),
      workAnniversaries: (json['workAnniversaries'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(
            (a) => TodayWorkAnniversary(
              employeeId: a['employeeId'] as String,
              fullName: a['fullName'] as String,
              yearsOfService: a['yearsOfService'] as int,
              profilePhotoUrl: a['profilePhotoUrl'] as String?,
            ),
          )
          .toList(),
      holiday: holidayJson == null
          ? null
          : TodayHoliday(
              name: holidayJson['name'] as String,
              date: holidayJson['date'] as String,
            ),
      notices: (json['notices'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(
            (n) => TodayNotice(
              id: n['id'] as String,
              title: n['title'] as String,
              authorName: n['authorName'] as String,
            ),
          )
          .toList(),
    );
  }
}
