import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Employee } from './employee.entity';

@Entity('employee_audit_logs')
export class EmployeeAuditLog extends BaseEntity {
  @Column()
  employeeId: string;

  @ManyToOne(() => Employee, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'employeeId' })
  employee: Employee;

  @Column()
  actorUserId: string;

  /** Snapshot of the actor's display name at the time of the change, so the
   * log stays readable even if that user is later renamed or removed. */
  @Column()
  actorName: string;

  /** Human-readable field label, e.g. "Employment Status", "Resume". */
  @Column()
  fieldLabel: string;

  @Column({ type: 'text', nullable: true })
  oldValue: string | null;

  @Column({ type: 'text', nullable: true })
  newValue: string | null;
}
