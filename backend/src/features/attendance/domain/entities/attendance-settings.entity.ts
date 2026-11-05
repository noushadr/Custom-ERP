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

  /** Arriving after this time isn't a "late" mark: the day is an Hours Cut
   * day instead (the missed hours are cut rather than counting toward the
   * every-third-late deduction). */
  @Column({ type: 'varchar', length: 5, default: '11:30' })
  hoursCutAfter: string;

  /** The time whole hours are counted from on an Hours Cut day: arriving at
   * 11:45 with this at 10:30 cuts one hour (1h15m, minutes dropped). */
  @Column({ type: 'varchar', length: 5, default: '10:30' })
  hoursCutFrom: string;

  /** Minutes after [shiftStart] before someone counts as late. */
  @Column({ type: 'int', default: 15 })
  graceMinutes: number;

  @Column({ type: 'timestamptz', nullable: true })
  lastSyncAt?: Date | null;

  @Column({ type: 'text', nullable: true })
  lastSyncMessage?: string | null;
}
