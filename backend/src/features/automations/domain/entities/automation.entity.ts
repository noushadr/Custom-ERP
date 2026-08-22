import { Column, Entity } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { AutomationType } from '../enums/automation-type.enum';

/** One row per AutomationType, upserted at startup (see
 * AutomationsService.onModuleInit) — never created/deleted by admins,
 * only toggled and configured. */
@Entity('automations')
export class Automation extends BaseEntity {
  @Column({
    type: 'enum',
    enum: AutomationType,
    enumName: 'automation_type_enum',
    unique: true,
  })
  type: AutomationType;

  @Column({ default: false })
  isActive: boolean;

  /** Only meaningful for the two reminder types — how many days before the
   * trigger date (renewalDate/dueDate) to notify. Null for annual leave
   * reset, whose trigger is intrinsic to the leave year rollover. */
  @Column({ type: 'int', nullable: true, default: 7 })
  daysBefore: number | null;

  /** Snapshot of whoever last changed this automation's config — null
   * until the first update, since every row starts out system-seeded. */
  @Column({ type: 'varchar', nullable: true })
  updatedByName?: string | null;
}
