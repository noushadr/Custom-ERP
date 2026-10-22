import 'package:zera_erp/features/notices/domain/entities/notice.dart';
import 'package:zera_erp/features/notices/domain/entities/notice_display_duration.dart';
import 'package:zera_erp/features/notices/domain/repositories/notice_repository.dart';

class FakeNoticeRepository implements NoticeRepository {
  FakeNoticeRepository({
    this.notices = const [],
    this.createError,
    this.updateError,
    this.deleteError,
  });

  final List<Notice> notices;
  final Object? createError;
  final Object? updateError;
  final Object? deleteError;

  /// The most recently created notice's title, if any.
  String? lastCreatedTitle;
  String? lastUpdatedId;
  String? lastUpdatedTitle;
  String? lastUpdatedBody;
  NoticeDisplayDuration? lastCreatedDuration;
  NoticeDisplayDuration? lastUpdatedDuration;
  bool? lastIncludeExpired;
  String? lastDeletedId;

  @override
  Future<List<Notice>> getAll({bool includeExpired = false}) async {
    lastIncludeExpired = includeExpired;
    return includeExpired
        ? notices
        : notices.where((notice) => !notice.isExpired).toList();
  }

  @override
  Future<Notice> create({
    required String title,
    required String body,
    NoticeDisplayDuration? displayDuration,
  }) async {
    lastCreatedTitle = title;
    lastCreatedDuration = displayDuration;
    if (createError != null) throw createError!;
    return Notice(
      id: 'notice-new',
      title: title,
      body: body,
      authorName: 'Test Author',
      createdAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<Notice> update(
    String id, {
    String? title,
    String? body,
    NoticeDisplayDuration? displayDuration,
  }) async {
    lastUpdatedId = id;
    lastUpdatedDuration = displayDuration;
    lastUpdatedTitle = title;
    lastUpdatedBody = body;
    if (updateError != null) throw updateError!;
    final existing = notices.firstWhere((notice) => notice.id == id);
    return Notice(
      id: id,
      title: title ?? existing.title,
      body: body ?? existing.body,
      authorName: existing.authorName,
      createdAt: existing.createdAt,
    );
  }

  @override
  Future<void> delete(String id) async {
    lastDeletedId = id;
    if (deleteError != null) throw deleteError!;
  }
}
