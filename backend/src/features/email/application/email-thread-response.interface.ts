import { MailboxKind } from './email.service';

export interface ThreadSummaryResponse {
  threadId: string;
  subject: string;
  participants: string[];
  lastDate: string;
  messageCount: number;
  hasUnread: boolean;
  hasInboxMessage: boolean;
  hasSentMessage: boolean;
}

export interface ThreadMessageResponse {
  mailbox: MailboxKind;
  uid: number;
  from: string;
  fromName: string | null;
  to: string | null;
  toName: string | null;
  date: string;
  text: string;
  isUnread: boolean;
}

export interface ThreadDetailResponse {
  threadId: string;
  subject: string;
  messages: ThreadMessageResponse[];
}
