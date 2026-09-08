import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Employee } from '../../../employee/domain/entities/employee.entity';

/** One goal set for one employee — by Admin/HR (any employee) or a Team
 * Lead (only for their own direct reports, enforced in `GoalsService`, not
 * a DB constraint). No status/progress tracking — just what the goal is,
 * who set it, and when; the employee sees it read-only on their own
 * dashboard. */
@Entity('employee_goals')
export class EmployeeGoal extends BaseEntity {
  @Column()
  employeeId: string;

  @ManyToOne(() => Employee, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'employeeId' })
  employee: Employee;

  @Column()
  title: string;

  @Column({ type: 'text', nullable: true })
  description?: string | null;

  @Column()
  createdByUserId: string;

  /** Snapshot of the creator's name at creation time — same convention as
   * `Notice.authorName`/`EmployeeRequest.hrDecisionByName`. */
  @Column()
  createdByName: string;
}
