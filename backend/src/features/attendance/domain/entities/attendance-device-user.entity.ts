import { Column, Entity, PrimaryColumn } from 'typeorm';

/** A person enrolled on the machine, as last seen by a sync — lets HR link
 * machine users to employees without the machine being online. */
@Entity('attendance_device_users')
export class AttendanceDeviceUser {
  @PrimaryColumn({ type: 'varchar' })
  deviceUserId: string;

  @Column({ type: 'varchar' })
  name: string;

  /** Someone still enrolled on the machine who no longer works here — kept
   * out of linking and out of the "unlinked" list. */
  @Column({ type: 'boolean', default: false })
  ignored: boolean;
}
