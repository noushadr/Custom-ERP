import '../entities/today_announcements.dart';

abstract interface class AnnouncementsRepository {
  /// Throws [AnnouncementsException] on failure.
  Future<TodayAnnouncements> getToday();
}
