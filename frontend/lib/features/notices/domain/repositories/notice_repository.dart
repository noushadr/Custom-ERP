import '../entities/notice.dart';

abstract interface class NoticeRepository {
  /// Throws [NoticeException] on failure.
  Future<List<Notice>> getAll();

  /// Requires `notices.manage`.
  Future<Notice> create({required String title, required String body});

  /// Requires `notices.manage`.
  Future<void> delete(String id);
}
