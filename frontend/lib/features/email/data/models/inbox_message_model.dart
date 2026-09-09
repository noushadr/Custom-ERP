import '../../domain/entities/inbox_message.dart';

class InboxMessageModel extends InboxMessage {
  const InboxMessageModel({
    required super.uid,
    required super.from,
    super.fromName,
    required super.subject,
    required super.date,
    required super.isUnread,
  });

  factory InboxMessageModel.fromJson(Map<String, dynamic> json) =>
      InboxMessageModel(
        uid: json['uid'] as int,
        from: json['from'] as String,
        fromName: json['fromName'] as String?,
        subject: json['subject'] as String,
        date: DateTime.parse(json['date'] as String),
        isUnread: json['isUnread'] as bool,
      );
}

class EmailMessageDetailModel extends EmailMessageDetail {
  const EmailMessageDetailModel({
    required super.subject,
    required super.from,
    required super.date,
    required super.text,
  });

  factory EmailMessageDetailModel.fromJson(Map<String, dynamic> json) =>
      EmailMessageDetailModel(
        subject: json['subject'] as String,
        from: json['from'] as String,
        date: DateTime.parse(json['date'] as String),
        text: json['text'] as String,
      );
}
