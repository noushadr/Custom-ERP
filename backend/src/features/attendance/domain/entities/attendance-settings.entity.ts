import { Column, Entity, PrimaryColumn } from 'typeorm';

/** The single settings row (id 1): the working-hours rule used to decide
 * who was late or left early, plus the last machine sync's outcome. */
@Entity('attendance_settings')
export class AttendanceSettings {
  @PrimaryColumn({ type: 'int' })
  id: number;

  /** "HH:mm", Pakistan time. */
  @Column({ type: 'varchar', length: 5, default: '11:00' })
  shiftStart: string;

  @Column({ type: 'varchar', length: 5, default: '19:00' })
  shiftEnd: string;

  /** Minutes after [shiftStart] before someone counts as late. */
  @Column({ type: 'int', default: 15 })
  graceMinutes: number;

  @Column({ type: 'timestamptz', nullable: true })
  lastSyncAt?: Date | null;

  @Column({ type: 'text', nullable: true })
  lastSyncMessage?: string | null;
}
