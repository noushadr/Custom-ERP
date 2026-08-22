import { Notification } from '../entities/notification.entity';

export const NOTIFICATION_REPOSITORY = Symbol('NOTIFICATION_REPOSITORY');

export interface NotificationRepository {
  findForUser(userId: string, unreadOnly: boolean): Promise<Notification[]>;
  findById(id: string): Promise<Notification | null>;
  save(notification: Notification): Promise<Notification>;
  markAllReadForUser(userId: string): Promise<void>;
}
