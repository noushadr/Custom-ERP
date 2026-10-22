import '../entities/notice.dart';
import '../entities/notice_display_duration.dart';

abstract interface class NoticeRepository {
  /// The notices still showing. With [includeExpired] it also returns expired
  /// ones, but only for `notices.manage` holders (the server ignores the flag
  /// for everyone else). Throws [NoticeException] on failure.
  Future<List<Notice>> getAll({bool includeExpired = false});

  /// Requires `notices.manage`. [displayDuration] defaults to always.
  Future<Notice> create({
    required String title,
    required String body,
    NoticeDisplayDuration? displayDuration,
  });

  /// Requires `notices.manage`. Passing [displayDuration] restarts the display
  /// window from now (bringing an expired notice back); null leaves it alone.
  Future<Notice> update(
    String id, {
    String? title,
    String? body,
    NoticeDisplayDuration? displayDuration,
  });

  /// Requires `notices.manage`.
  Future<void> delete(String id);
}
