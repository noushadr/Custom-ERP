import 'package:zera_erp/features/notices/domain/entities/notice.dart';
import 'package:zera_erp/features/notices/domain/repositories/notice_repository.dart';

class FakeNoticeRepository implements NoticeRepository {
  FakeNoticeRepository({this.notices = const [], this.createError});

  final List<Notice> notices;
  final Object? createError;

  /// The most recently created notice's title, if any.
  String? lastCreatedTitle;

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
}
