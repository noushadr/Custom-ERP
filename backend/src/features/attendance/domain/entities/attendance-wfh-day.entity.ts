import { Column, Entity } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';

/** A company-wide "work from home" day. On it nobody's machine scans count:
 * HR marks who worked (see AttendanceWfhPresence), and those people are just
 * "present" — no clock in/out, grace time or late hours. */
@Entity('attendance_wfh_days')
export class AttendanceWfhDay extends BaseEntity {
  /** yyyy-MM-dd */
  @Column({ type: 'varchar', length: 10, unique: true })
  date: string;

  @Column({ type: 'text', nullable: true })
  note?: string | null;
}
