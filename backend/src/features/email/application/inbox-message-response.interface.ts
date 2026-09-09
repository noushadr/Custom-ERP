export interface InboxMessageResponse {
  uid: number;
  from: string;
  fromName: string | null;
  subject: string;
  date: string;
  isUnread: boolean;
}
