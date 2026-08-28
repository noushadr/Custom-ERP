import { TaskComment } from '../entities/task-comment.entity';

export const TASK_COMMENT_REPOSITORY = Symbol('TASK_COMMENT_REPOSITORY');

export interface TaskCommentRepository {
  findByTaskId(taskId: string): Promise<TaskComment[]>;
  save(comment: TaskComment): Promise<TaskComment>;
}
