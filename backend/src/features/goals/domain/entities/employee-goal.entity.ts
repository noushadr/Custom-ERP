import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Employee } from '../../../employee/domain/entities/employee.entity';

/** One goal set for one employee — by Admin/HR (any employee), a Team Lead
 * (only for their own direct reports), or the employee themselves (only
 * their own), all enforced in `GoalsService`, not a DB constraint — no
 * approval step for any of the three. Tracks how much of it is done via
 * `achievementPercentage` — settable by Admin/HR or by the employee on
 * their own goal, never by a Team Lead editing a direct report's goal
 * (`updateAsManager` ignores it even if sent). */
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

  @Column({ type: 'int', default: 0 })
  achievementPercentage: number;

  /** Soft-hidden instead of deleted — `GoalsService.archive` sets this
   * rather than removing the row, so past goal-setting is never destroyed.
   * Every read query filters `archived: false`. */
  @Column({ default: false })
  archived: boolean;

  @Column()
  createdByUserId: string;

  /** Snapshot of the creator's name at creation time — same convention as
   * `Notice.authorName`/`EmployeeRequest.hrDecisionByName`. */
  @Column()
  createdByName: string;
}
