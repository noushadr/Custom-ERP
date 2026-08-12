import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Employee } from '../../../employee/domain/entities/employee.entity';
import { LeaveType } from './leave-type.entity';

/** One row per (employee, leave type, year) — never overwritten across
 * years, so last year's balance stays queryable for auditing/reporting once
 * the new year's row is created by the annual reset. */
@Entity('leave_balances')
@Index(['employeeId', 'leaveTypeId', 'year'], { unique: true })
export class LeaveBalance extends BaseEntity {
  @Column()
  employeeId: string;

  @ManyToOne(() => Employee, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'employeeId' })
  employee: Employee;

  @Column()
  leaveTypeId: string;

  @ManyToOne(() => LeaveType, { eager: true })
  @JoinColumn({ name: 'leaveTypeId' })
  leaveType: LeaveType;

  @Column()
  year: number;

  @Column({ type: 'numeric', precision: 5, scale: 1 })
  allocated: string;

  @Column({ type: 'numeric', precision: 5, scale: 1, default: 0 })
  used: string;
}
