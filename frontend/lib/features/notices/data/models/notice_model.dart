import '../../domain/entities/notice.dart';

class NoticeModel extends Notice {
  const NoticeModel({
    required super.id,
    required super.title,
    required super.body,
    required super.authorName,
    required super.createdAt,
  });

  factory NoticeModel.fromJson(Map<String, dynamic> json) => NoticeModel(
    id: json['id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    authorName: json['authorName'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
