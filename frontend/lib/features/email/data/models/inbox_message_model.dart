import '../../domain/entities/inbox_message.dart';

class InboxMessageModel extends InboxMessage {
  const InboxMessageModel({
    required super.uid,
    required super.from,
    super.fromName,
    super.to,
    super.toName,
    required super.subject,
    required super.date,
    required super.isUnread,
  });

  factory InboxMessageModel.fromJson(Map<String, dynamic> json) =>
      InboxMessageModel(
        uid: json['uid'] as int,
        from: json['from'] as String,
        fromName: json['fromName'] as String?,
        to: json['to'] as String?,
        toName: json['toName'] as String?,
        subject: json['subject'] as String,
        date: DateTime.parse(json['date'] as String),
        isUnread: json['isUnread'] as bool,
      );
}

class EmailMessageDetailModel extends EmailMessageDetail {
  const EmailMessageDetailModel({
    required super.subject,
    required super.from,
    super.to,
    required super.date,
    required super.text,
  });

  factory EmailMessageDetailModel.fromJson(Map<String, dynamic> json) =>
      EmailMessageDetailModel(
        subject: json['subject'] as String,
        from: json['from'] as String,
        to: json['to'] as String?,
        date: DateTime.parse(json['date'] as String),
        text: json['text'] as String,
      );
}

class EmailThreadModel extends EmailThread {
  const EmailThreadModel({
    required super.threadId,
    required super.subject,
    required super.participants,
    required super.lastDate,
    required super.messageCount,
    required super.hasUnread,
    required super.hasInboxMessage,
    required super.hasSentMessage,
  });

  factory EmailThreadModel.fromJson(Map<String, dynamic> json) =>
      EmailThreadModel(
        threadId: json['threadId'] as String,
        subject: json['subject'] as String,
        participants: (json['participants'] as List<dynamic>)
            .cast<String>(),
        lastDate: DateTime.parse(json['lastDate'] as String),
        messageCount: json['messageCount'] as int,
        hasUnread: json['hasUnread'] as bool,
        hasInboxMessage: json['hasInboxMessage'] as bool,
        hasSentMessage: json['hasSentMessage'] as bool,
      );
}

class EmailThreadMessageModel extends EmailThreadMessage {
  const EmailThreadMessageModel({
    required super.mailbox,
    required super.uid,
    required super.from,
    super.fromName,
    super.to,
    super.toName,
    required super.date,
    required super.text,
    required super.isUnread,
  });

  factory EmailThreadMessageModel.fromJson(Map<String, dynamic> json) =>
      EmailThreadMessageModel(
        mailbox: json['mailbox'] as String,
        uid: json['uid'] as int,
        from: json['from'] as String,
        fromName: json['fromName'] as String?,
        to: json['to'] as String?,
        toName: json['toName'] as String?,
        date: DateTime.parse(json['date'] as String),
        text: json['text'] as String,
        isUnread: json['isUnread'] as bool,
      );
}

class EmailThreadDetailModel extends EmailThreadDetail {
  const EmailThreadDetailModel({
    required super.threadId,
    required super.subject,
    required super.messages,
  });

  factory EmailThreadDetailModel.fromJson(Map<String, dynamic> json) =>
      EmailThreadDetailModel(
        threadId: json['threadId'] as String,
        subject: json['subject'] as String,
        messages: (json['messages'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(EmailThreadMessageModel.fromJson)
            .toList(),
      );
}
