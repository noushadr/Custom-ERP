import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { Notification } from '../domain/entities/notification.entity';
import {
  NOTIFICATION_CATEGORY_LABELS,
  NotificationCategory,
} from '../domain/enums/notification-category.enum';
import { NotificationLinkTarget } from '../domain/enums/notification-link-target.enum';
import {
  NOTIFICATION_REPOSITORY,
  type NotificationRepository,
} from '../domain/repositories/notification-repository.interface';
import {
  NOTIFICATION_MUTE_PREFERENCE_REPOSITORY,
  type NotificationMutePreferenceRepository,
} from '../domain/repositories/notification-mute-preference-repository.interface';
import { NotificationResponseDto } from './notification-response.interface';
import { NotificationMutePreferenceResponseDto } from './notification-mute-preference-response.interface';
import { toNotificationResponse } from './notification.mapper';

@Injectable()
export class NotificationsService {
  constructor(
    @Inject(NOTIFICATION_REPOSITORY)
    private readonly notificationRepository: NotificationRepository,
    @Inject(NOTIFICATION_MUTE_PREFERENCE_REPOSITORY)
    private readonly mutePreferenceRepository: NotificationMutePreferenceRepository,
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

  /** Creates a notification for one recipient — called directly by each
   * feature module (tasks, leave, payroll, performance reviews) at the
   * lifecycle event it cares about, rather than through a generic
   * admin-toggleable automation layer. Silently skips creating the row at
   * all when the recipient has muted this `category` — the caller never
   * needs to check first, same as how every call site already doesn't
   * check permissions before notifying today. */
  async create(params: {
    recipientUserId: string;
    message: string;
    category: NotificationCategory;
    linkTarget?: NotificationLinkTarget;
    linkEntityId?: string;
  }): Promise<Notification | null> {
    const muted = await this.mutePreferenceRepository.isMuted(
      params.recipientUserId,
      params.category,
    );
    if (muted) return null;

    const notification = new Notification();
    notification.recipientUserId = params.recipientUserId;
    notification.message = params.message;
    notification.category = params.category;
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

  /** Every known category, each flagged with whether this viewer has muted
   * it — a flat "presence in the mute table = muted" read, with no need to
   * pre-populate a row per category for a user who's never touched any of
   * them. */
  async getMutePreferences(
    userId: string,
  ): Promise<NotificationMutePreferenceResponseDto[]> {
    const mutedCategories =
      await this.mutePreferenceRepository.findCategoriesForUser(userId);
    const mutedSet = new Set(mutedCategories);
    return Object.values(NotificationCategory).map((category) => ({
      category,
      label: NOTIFICATION_CATEGORY_LABELS[category],
      muted: mutedSet.has(category),
    }));
  }

  async setMutePreference(
    userId: string,
    category: NotificationCategory,
    muted: boolean,
  ): Promise<void> {
    if (muted) {
      await this.mutePreferenceRepository.mute(userId, category);
    } else {
      await this.mutePreferenceRepository.unmute(userId, category);
    }
  }
}
