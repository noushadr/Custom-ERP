import { NotificationCategory } from '../enums/notification-category.enum';

export const NOTIFICATION_MUTE_PREFERENCE_REPOSITORY = Symbol(
  'NOTIFICATION_MUTE_PREFERENCE_REPOSITORY',
);

export interface NotificationMutePreferenceRepository {
  findCategoriesForUser(userId: string): Promise<NotificationCategory[]>;
  isMuted(userId: string, category: NotificationCategory): Promise<boolean>;
  mute(userId: string, category: NotificationCategory): Promise<void>;
  unmute(userId: string, category: NotificationCategory): Promise<void>;
}
