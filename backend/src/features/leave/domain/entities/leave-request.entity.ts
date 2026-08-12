import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Employee } from '../../../employee/domain/entities/employee.entity';
import { LeaveRequestStatus } from '../enums/leave-request-status.enum';
import { LeaveType } from './leave-type.entity';

@Entity('leave_requests')
export class LeaveRequest extends BaseEntity {
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

  @Column({ type: 'date' })
  startDate: string;

  @Column({ type: 'date' })
  endDate: string;

  /** Working days (Mon-Fri) between startDate and endDate inclusive,
   * computed at submission time and stored so it stays stable. */
  @Column({ type: 'numeric', precision: 5, scale: 1 })
  numberOfDays: string;

  @Column({ type: 'text' })
  reason: string;

  @Column({
    type: 'enum',
    enum: LeaveRequestStatus,
    default: LeaveRequestStatus.SUBMITTED,
  })
  status: LeaveRequestStatus;

  @Column({ type: 'timestamptz', nullable: true })
  managerDecisionAt?: Date;

  @Column({ nullable: true })
  managerDecisionByName?: string;

  @Column({ type: 'text', nullable: true })
  managerComment?: string;

  @Column({ type: 'timestamptz', nullable: true })
  hrDecisionAt?: Date;

  @Column({ nullable: true })
  hrDecisionByName?: string;

  @Column({ type: 'text', nullable: true })
  hrComment?: string;

  @Column({ type: 'timestamptz', nullable: true })
  cancelledAt?: Date;
}
