import { Column, Entity } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';

@Entity('leave_types')
export class LeaveType extends BaseEntity {
  @Column({ unique: true })
  name: string;

  /** Days granted per year to every employee for this leave type. */
  @Column({ type: 'numeric', precision: 5, scale: 1 })
  annualAllowanceDays: string;

  /** Max unused days that may carry into the next year's allocation on
   * reset. Null/0 means no carry-forward. */
  @Column({ type: 'numeric', precision: 5, scale: 1, nullable: true })
  carryForwardLimitDays?: string;

  /** Hex color for the calendar's per-type dot/chip, e.g. "#00D5EE". */
  @Column({ nullable: true })
  colorHex?: string;

  @Column({ default: false })
  isArchived: boolean;
}
