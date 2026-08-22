export interface NotificationResponseDto {
  id: string;
  message: string;
  linkTarget: string | null;
  linkEntityId: string | null;
  isRead: boolean;
  createdAt: string;
}
