import { Task } from '../domain/entities/task.entity';
import { TaskAuditLog } from '../domain/entities/task-audit-log.entity';
import { TaskComment } from '../domain/entities/task-comment.entity';
import {
  TaskAuditLogResponseDto,
  TaskCommentResponseDto,
  TaskResponseDto,
} from './task-response.interface';

/** Flattens to a DTO before returning from a controller — same convention as
 * toKnowledgeBaseArticleResponse/toPerformanceReviewResponse. `assignee` is
 * null for a task still assigned to a team, not yet a person; `department`
 * always comes from Task's own stored column now, never derived from
 * `assignee.department` (that would have nothing to derive from once
 * `assignee` can be null). */
export function toTaskResponse(
  task: Task,
  commentCount = 0,
): TaskResponseDto {
  return {
    id: task.id,
    title: task.title,
    description: task.description,
    assigneeEmployeeId: task.assigneeEmployeeId,
    assigneeName: task.assignee
      ? `${task.assignee.firstName} ${task.assignee.lastName}`
      : null,
    assigneePhotoUrl: task.assignee?.profilePhotoUrl ?? null,
    departmentId: task.departmentId,
    departmentName: task.department?.name ?? null,
    assignedByUserId: task.assignedByUserId,
    assignedByName: task.assignedByName,
    assignedByPhotoUrl: task.assignedByPhotoUrl,
    priority: task.priority,
    dueDate: task.dueDate,
    status: task.status,
    progressRemarks: task.progressRemarks ?? null,
    completedAt: task.completedAt?.toISOString() ?? null,
    projectId: task.projectId ?? null,
    createdAt: task.createdAt.toISOString(),
    updatedAt: task.updatedAt.toISOString(),
    commentCount,
  };
}

export function toTaskCommentResponse(
  comment: TaskComment,
): TaskCommentResponseDto {
  return {
    id: comment.id,
    authorName: comment.authorName,
    body: comment.body,
    createdAt: comment.createdAt.toISOString(),
  };
}

export function toTaskAuditLogResponse(
  log: TaskAuditLog,
): TaskAuditLogResponseDto {
  return {
    id: log.id,
    actorName: log.actorName,
    fieldLabel: log.fieldLabel,
    oldValue: log.oldValue,
    newValue: log.newValue,
    createdAt: log.createdAt.toISOString(),
  };
}
