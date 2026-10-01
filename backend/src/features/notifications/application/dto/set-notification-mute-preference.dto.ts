import { IsBoolean, IsEnum } from 'class-validator';
import { NotificationCategory } from '../../domain/enums/notification-category.enum';

export class SetNotificationMutePreferenceDto {
  @IsEnum(NotificationCategory)
  category: NotificationCategory;

  @IsBoolean()
  muted: boolean;
}
