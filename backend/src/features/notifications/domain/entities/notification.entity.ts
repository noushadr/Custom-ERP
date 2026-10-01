import { Column, Entity, Index } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { NotificationCategory } from '../enums/notification-category.enum';
import { NotificationLinkTarget } from '../enums/notification-link-target.enum';

/** A persisted, per-user notification, created directly by whichever
 * feature module (tasks, leave, payroll, performance reviews) has something
 * worth telling a user about. V1 is in-app only, no email/push delivery
 * yet. */
@Entity('notifications')
export class Notification extends BaseEntity {
  @Index()
  @Column()
  recipientUserId: string;

  @Column({ type: 'text' })
  message: string;

  @Column({
    type: 'enum',
    enum: NotificationLinkTarget,
    enumName: 'notification_link_target_enum',
    nullable: true,
  })
  linkTarget: NotificationLinkTarget | null;

  /** Id of the entity the notification is about (a project, task, etc.) —
   * meaning depends on `linkTarget`. Null when there's nothing to deep-link
   * to (e.g. a leave-reset notice). */
  @Column({ type: 'varchar', nullable: true })
  linkEntityId: string | null;

  @Column({ default: false })
  isRead: boolean;

  /** Nullable, unlike every other column here with a real default, on
   * purpose: backfilling this on the real rows already in this dev
   * database would mean guessing a category for historical notifications
   * that predate this column, which isn't this app's call to make (same
   * reasoning `probationEndDate` stayed nullable for pre-existing
   * employees). Every call site going forward always sets it; a `null` row
   * is simply never affected by a mute preference, same as it wasn't
   * mutable before this feature existed. */
  @Column({
    type: 'enum',
    enum: NotificationCategory,
    enumName: 'notification_category_enum',
    nullable: true,
  })
  category: NotificationCategory | null;
}
