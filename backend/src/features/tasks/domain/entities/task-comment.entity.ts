import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Task } from './task.entity';

/** An append-only comment thread entry — no edit/delete, matching how
 * Knowledge Base article versions are append-only. */
@Entity('task_comments')
export class TaskComment extends BaseEntity {
  @Column()
  taskId: string;

  @ManyToOne(() => Task, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'taskId' })
  task: Task;

  @Column()
  authorUserId: string;

  /** Snapshot of the author's display name at post time. */
  @Column()
  authorName: string;

  @Column({ type: 'text' })
  body: string;
}
