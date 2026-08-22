import '../../domain/entities/task_comment.dart';

class TaskCommentModel extends TaskComment {
  const TaskCommentModel({
    required super.id,
    required super.authorName,
    required super.body,
    required super.createdAt,
  });

  factory TaskCommentModel.fromJson(Map<String, dynamic> json) =>
      TaskCommentModel(
        id: json['id'] as String,
        authorName: json['authorName'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
