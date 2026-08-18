import 'package:zera_erp/features/notices/domain/entities/notice.dart';
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
  String? lastDeletedId;

  @override
  Future<List<Notice>> getAll() async => notices;

  @override
  Future<Notice> create({required String title, required String body}) async {
    lastCreatedTitle = title;
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
  Future<Notice> update(String id, {String? title, String? body}) async {
    lastUpdatedId = id;
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
