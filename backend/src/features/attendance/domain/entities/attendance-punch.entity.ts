import { Column, Entity, Index, Unique } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';

/** One raw check-in/out scan from the attendance machine. A day's clock in
 * and out are derived from these on read — never stored. */
@Entity('attendance_punches')
@Unique('UQ_attendance_punch_user_time', ['deviceUserId', 'punchedAt'])
export class AttendancePunch extends BaseEntity {
  /** The machine's own user id ("AC-No."), linked to an employee via
   * `Employee.attendanceId`. */
  @Column({ type: 'varchar' })
  deviceUserId: string;

  @Index()
  @Column({ type: 'timestamptz' })
  punchedAt: Date;
}
