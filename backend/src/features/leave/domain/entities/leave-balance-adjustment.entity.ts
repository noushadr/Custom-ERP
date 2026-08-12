import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Employee } from '../../../employee/domain/entities/employee.entity';
import { LeaveType } from './leave-type.entity';

/** Append-only audit trail for manual HR/Admin balance edits — mirrors
 * SalaryRecord's history-of-changes shape. */
@Entity('leave_balance_adjustments')
export class LeaveBalanceAdjustment extends BaseEntity {
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

  /** Positive to grant extra days, negative to deduct. */
  @Column({ type: 'numeric', precision: 5, scale: 1 })
  deltaDays: string;

  @Column({ type: 'text' })
  reason: string;

  @Column()
  actorUserId: string;

  @Column()
  actorName: string;
}
