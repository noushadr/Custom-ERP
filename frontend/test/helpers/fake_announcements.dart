import 'package:zera_erp/features/announcements/domain/entities/today_announcements.dart';
import 'package:zera_erp/features/announcements/domain/repositories/announcements_repository.dart';

class FakeAnnouncementsRepository implements AnnouncementsRepository {
  FakeAnnouncementsRepository({
    this.today = const TodayAnnouncements(
      birthdays: [],
      workAnniversaries: [],
      holiday: null,
      notices: [],
      employeeOfTheMonth: null,
    ),
    this.getTodayError,
  });

  final TodayAnnouncements today;
  final Object? getTodayError;

  @override
  Future<TodayAnnouncements> getToday() async {
    if (getTodayError != null) throw getTodayError!;
    return today;
  }
}
