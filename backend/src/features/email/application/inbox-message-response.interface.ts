export interface InboxMessageResponse {
  uid: number;
  from: string;
  fromName: string | null;
  /** The recipient — only meaningful (and only populated) for the Sent
   * mailbox, where "who is this to" matters more than "who is this from"
   * (always the viewer's own address). */
  to: string | null;
  toName: string | null;
  subject: string;
  date: string;
  isUnread: boolean;
}
