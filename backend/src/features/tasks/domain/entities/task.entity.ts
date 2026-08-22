import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Project } from '../../../clients/domain/entities/project.entity';
import { Employee } from '../../../employee/domain/entities/employee.entity';
import { TaskPriority } from '../enums/task-priority.enum';
import { TaskStatus } from '../enums/task-status.enum';

/** A single-assignee task. `assignee` is eager-loaded (which itself eager-
 * loads `Employee.department`), so "which department/team does this task
 * belong to" is always `task.assignee.department` — never its own stored
 * column, so it can never drift out of sync when an assignee is changed or
 * transferred. */
@Entity('tasks')
export class Task extends BaseEntity {
  @Column()
  title: string;

  @Column({ type: 'text', nullable: true })
  description: string | null;

  @Column()
  assigneeEmployeeId: string;

  @ManyToOne(() => Employee, { eager: true })
  @JoinColumn({ name: 'assigneeEmployeeId' })
  assignee: Employee;

  @Column()
  assignedByUserId: string;

  /** Snapshot of the assigner's display name — updated together with
   * `assignedByUserId` on reassignment, so history stays readable even if
   * that user is later renamed or removed. */
  @Column()
  assignedByName: string;

  /** Snapshot of the assigner's photo at assignment time, same reasoning as
   * `assignedByName` — null if they had no photo or no Employee profile. */
  @Column({ type: 'varchar', nullable: true })
  assignedByPhotoUrl: string | null;

  @Column({ type: 'enum', enum: TaskPriority, default: TaskPriority.MEDIUM })
  priority: TaskPriority;

  @Column({ type: 'date' })
  dueDate: string;

  /** Which `dueDate` value the daily deadline-reminder check last notified
   * for — not `dueDate` itself, so a repeated check never sends a duplicate
   * reminder, while changing `dueDate` naturally makes it eligible again. */
  @Column({ type: 'date', nullable: true })
  lastDeadlineReminderSentFor?: string | null;

  @Column({ type: 'enum', enum: TaskStatus, default: TaskStatus.TODO })
  status: TaskStatus;

  @Column({ type: 'timestamptz', nullable: true })
  completedAt: Date | null;

  /** Optional link to a Clients & Projects project — set only by a
   * `clients.manage` holder (see TasksService.linkToProject). Unrelated to
   * this task's own visibility/authorization for its assignee, which stays
   * exactly the same whether or not it's linked to a project. */
  @Column({ type: 'varchar', nullable: true })
  projectId: string | null;

  @ManyToOne(() => Project, { nullable: true })
  @JoinColumn({ name: 'projectId' })
  project?: Project;
}
