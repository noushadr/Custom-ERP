import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { Notification } from '../domain/entities/notification.entity';
import { NotificationLinkTarget } from '../domain/enums/notification-link-target.enum';
import {
  NOTIFICATION_REPOSITORY,
  type NotificationRepository,
} from '../domain/repositories/notification-repository.interface';
import { NotificationResponseDto } from './notification-response.interface';
import { toNotificationResponse } from './notification.mapper';

@Injectable()
export class NotificationsService {
  constructor(
    @Inject(NOTIFICATION_REPOSITORY)
    private readonly notificationRepository: NotificationRepository,
  ) {}

  async getForUser(
    userId: string,
    unreadOnly: boolean,
  ): Promise<NotificationResponseDto[]> {
    const notifications = await this.notificationRepository.findForUser(
      userId,
      unreadOnly,
    );
    return notifications.map(toNotificationResponse);
  }

  /** Creates a notification for one recipient — the only way any
   * notification comes into existence today (the Automations module calls
   * this as its "action"). */
  async create(params: {
    recipientUserId: string;
    message: string;
    linkTarget?: NotificationLinkTarget;
    linkEntityId?: string;
  }): Promise<Notification> {
    const notification = new Notification();
    notification.recipientUserId = params.recipientUserId;
    notification.message = params.message;
    notification.linkTarget = params.linkTarget ?? null;
    notification.linkEntityId = params.linkEntityId ?? null;
    notification.isRead = false;
    return this.notificationRepository.save(notification);
  }

  async markRead(id: string, userId: string): Promise<NotificationResponseDto> {
    const notification = await this.notificationRepository.findById(id);
    if (!notification || notification.recipientUserId !== userId) {
      throw new NotFoundException('Notification not found');
    }
    notification.isRead = true;
    const saved = await this.notificationRepository.save(notification);
    return toNotificationResponse(saved);
  }

  async markAllRead(userId: string): Promise<void> {
    await this.notificationRepository.markAllReadForUser(userId);
  }
}
