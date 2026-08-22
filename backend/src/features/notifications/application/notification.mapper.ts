import { Notification } from '../domain/entities/notification.entity';
import { NotificationResponseDto } from './notification-response.interface';

export function toNotificationResponse(
  notification: Notification,
): NotificationResponseDto {
  return {
    id: notification.id,
    message: notification.message,
    linkTarget: notification.linkTarget,
    linkEntityId: notification.linkEntityId,
    isRead: notification.isRead,
    createdAt: notification.createdAt.toISOString(),
  };
}
