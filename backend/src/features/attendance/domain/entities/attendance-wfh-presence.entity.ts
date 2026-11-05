import { Column, Entity, Unique } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';

/** HR's manual mark that an employee worked on a work-from-home day. */
@Entity('attendance_wfh_presence')
@Unique('UQ_wfh_presence_employee_date', ['employeeId', 'date'])
export class AttendanceWfhPresence extends BaseEntity {
  @Column({ type: 'uuid' })
  employeeId: string;

  /** yyyy-MM-dd */
  @Column({ type: 'varchar', length: 10 })
  date: string;
}
