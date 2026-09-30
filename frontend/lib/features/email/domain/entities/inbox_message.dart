class InboxMessage {
  const InboxMessage({
    required this.uid,
    required this.from,
    this.fromName,
    this.to,
    this.toName,
    required this.subject,
    required this.date,
    required this.isUnread,
  });

  final int uid;
  final String from;
  final String? fromName;

  /// Only populated for the Sent mailbox — who the message was sent to.
  final String? to;
  final String? toName;
  final String subject;
  final DateTime date;
  final bool isUnread;
}

class EmailMessageDetail {
  const EmailMessageDetail({
    required this.subject,
    required this.from,
    this.to,
    required this.date,
    required this.text,
  });

  final String subject;
  final String from;
  final String? to;
  final DateTime date;
  final String text;
}

/// A Gmail-style conversation: every message sharing a subject (after
/// stripping "Re:"/"Fwd:" prefixes) across the mailbox's Inbox and Sent
/// folders. [hasInboxMessage]/[hasSentMessage] say which of the Inbox/Sent
/// tabs this conversation shows up under.
class EmailThread {
  const EmailThread({
    required this.threadId,
    required this.subject,
    required this.participants,
    required this.lastDate,
    required this.messageCount,
    required this.hasUnread,
    required this.hasInboxMessage,
    required this.hasSentMessage,
  });

  final String threadId;
  final String subject;
  final List<String> participants;
  final DateTime lastDate;
  final int messageCount;
  final bool hasUnread;
  final bool hasInboxMessage;
  final bool hasSentMessage;
}

class EmailThreadMessage {
  const EmailThreadMessage({
    required this.mailbox,
    required this.uid,
    required this.from,
    this.fromName,
    this.to,
    this.toName,
    required this.date,
    required this.text,
    required this.isUnread,
  });

  /// `'inbox'` or `'sent'` — which folder this particular message in the
  /// conversation lives in.
  final String mailbox;
  final int uid;
  final String from;
  final String? fromName;
  final String? to;
  final String? toName;
  final DateTime date;
  final String text;
  final bool isUnread;
}

class EmailThreadDetail {
  const EmailThreadDetail({
    required this.threadId,
    required this.subject,
    required this.messages,
  });

  final String threadId;
  final String subject;

  /// Oldest first, matching Gmail's own conversation ordering.
  final List<EmailThreadMessage> messages;
}
