import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Department } from '../../../departments/domain/entities/department.entity';
import { Project } from '../../../clients/domain/entities/project.entity';
import { Employee } from '../../../employee/domain/entities/employee.entity';
import { TaskPriority } from '../enums/task-priority.enum';
import { TaskStatus } from '../enums/task-status.enum';

/** A task's `assigneeEmployeeId` is nullable — a task can be assigned to a
 * whole team (`departmentId` set, `assigneeEmployeeId` null) until either
 * that team's head picks a specific member or a member claims it themself
 * (see `TasksService.assignTeamMember`/`claimTask`). `departmentId` is its
 * own stored column (not derived from `assignee.department` like before)
 * precisely so a team-only task still has a department with no assignee to
 * derive it from; once claimed, it's left as-is rather than re-derived, so
 * it can never silently change if the assignee is later transferred. */
@Entity('tasks')
export class Task extends BaseEntity {
  @Column()
  title: string;

  @Column({ type: 'text', nullable: true })
  description: string | null;

  @Column({ nullable: true })
  assigneeEmployeeId: string | null;

  @ManyToOne(() => Employee, { eager: true, nullable: true })
  @JoinColumn({ name: 'assigneeEmployeeId' })
  assignee: Employee | null;

  @Column({ nullable: true })
  departmentId: string | null;

  @ManyToOne(() => Department, { eager: true, nullable: true })
  @JoinColumn({ name: 'departmentId' })
  department: Department | null;

  /** Free-text progress notes — settable by the assignee alongside status/
   * due date (see `TasksService.updateProgress`), or by anyone who can edit
   * the task's other fields. */
  @Column({ type: 'text', nullable: true })
  progressRemarks: string | null;

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
