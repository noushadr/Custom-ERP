import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Task } from './task.entity';

/** A field-change log for a task's history — identical shape to
 * EmployeeAuditLog. One row per changed field (or a single "Created" row at
 * creation), so "who created, assigned, updated, and completed" this task
 * is a plain readable timeline. */
@Entity('task_audit_logs')
export class TaskAuditLog extends BaseEntity {
  @Column()
  taskId: string;

  @ManyToOne(() => Task, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'taskId' })
  task: Task;

  @Column()
  actorUserId: string;

  /** Snapshot of the actor's display name at the time of the change. */
  @Column()
  actorName: string;

  /** Human-readable field label, e.g. "Status", "Assignee", "Priority",
   * "Due Date" — "Created" for the initial row. */
  @Column()
  fieldLabel: string;

  @Column({ type: 'text', nullable: true })
  oldValue: string | null;

  @Column({ type: 'text', nullable: true })
  newValue: string | null;
}
