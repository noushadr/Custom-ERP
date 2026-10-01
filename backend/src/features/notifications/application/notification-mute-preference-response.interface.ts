import { NotificationCategory } from '../domain/enums/notification-category.enum';

export interface NotificationMutePreferenceResponseDto {
  category: NotificationCategory;
  label: string;
  muted: boolean;
}
