import { TaskAuditLog } from '../entities/task-audit-log.entity';

export const TASK_AUDIT_LOG_REPOSITORY = Symbol('TASK_AUDIT_LOG_REPOSITORY');

export interface TaskAuditLogRepository {
  findByTaskId(taskId: string): Promise<TaskAuditLog[]>;
  save(log: TaskAuditLog): Promise<TaskAuditLog>;
}
