class InboxMessage {
  const InboxMessage({
    required this.uid,
    required this.from,
    this.fromName,
    required this.subject,
    required this.date,
    required this.isUnread,
  });

  final int uid;
  final String from;
  final String? fromName;
  final String subject;
  final DateTime date;
  final bool isUnread;
}

class EmailMessageDetail {
  const EmailMessageDetail({
    required this.subject,
    required this.from,
    required this.date,
    required this.text,
  });

  final String subject;
  final String from;
  final DateTime date;
  final String text;
}
