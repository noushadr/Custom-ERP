import { Column, Entity, Index, Unique } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { NotificationCategory } from '../enums/notification-category.enum';

/** A row existing means this user has muted this category — flat
 * "presence = muted" table rather than a boolean column, so a brand-new
 * user has zero rows (nothing muted) with no need to pre-populate one row
 * per category per user. Deleting the row un-mutes it. */
@Entity('notification_mute_preferences')
@Unique(['userId', 'category'])
export class NotificationMutePreference extends BaseEntity {
  @Index()
  @Column()
  userId: string;

  @Column({
    type: 'enum',
    enum: NotificationCategory,
    enumName: 'notification_category_enum',
  })
  category: NotificationCategory;
}
