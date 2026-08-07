import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Employee } from '../../../employee/domain/entities/employee.entity';
import { RequestStatus } from '../enums/request-status.enum';

@Entity('employee_requests')
export class EmployeeRequest extends BaseEntity {
  @Column()
  employeeId: string;

  @ManyToOne(() => Employee, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'employeeId' })
  employee: Employee;

  @Column()
  subject: string;

  @Column({ type: 'text' })
  description: string;

  /** Free-text category, e.g. "Equipment", "Document" — not a fixed enum,
   * unrelated to the separate Leave Management module. */
  @Column({ nullable: true })
  type?: string;

  @Column({
    type: 'enum',
    enum: RequestStatus,
    default: RequestStatus.SUBMITTED,
  })
  status: RequestStatus;

  @Column({ type: 'timestamptz', nullable: true })
  managerDecisionAt?: Date;

  /** Snapshot of the deciding manager's name at decision time. */
  @Column({ nullable: true })
  managerDecisionByName?: string;

  @Column({ type: 'timestamptz', nullable: true })
  hrDecisionAt?: Date;

  /** Snapshot of the deciding HR/Admin's name at decision time. */
  @Column({ nullable: true })
  hrDecisionByName?: string;

  @Column({ type: 'text', nullable: true })
  rejectionReason?: string;
}
