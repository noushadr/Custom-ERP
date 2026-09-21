import { TaskComment } from '../entities/task-comment.entity';

export const TASK_COMMENT_REPOSITORY = Symbol('TASK_COMMENT_REPOSITORY');

export interface TaskCommentRepository {
  findByTaskId(taskId: string): Promise<TaskComment[]>;
  save(comment: TaskComment): Promise<TaskComment>;
  /** Bulk comment counts for a list of tasks (one query, not N) — keyed by
   * taskId, with no entry at all for a task that has zero comments. */
  countByTaskIds(taskIds: string[]): Promise<Map<string, number>>;
}
