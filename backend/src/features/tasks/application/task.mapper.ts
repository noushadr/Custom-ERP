import { Task } from '../domain/entities/task.entity';
import { TaskAuditLog } from '../domain/entities/task-audit-log.entity';
import { TaskComment } from '../domain/entities/task-comment.entity';
import {
  TaskAuditLogResponseDto,
  TaskCommentResponseDto,
  TaskResponseDto,
} from './task-response.interface';

/** Flattens to a DTO before returning from a controller — same convention as
 * toKnowledgeBaseArticleResponse/toPerformanceReviewResponse. `departmentId`/
 * `departmentName` are derived from the eager-loaded `assignee.department`
 * rather than stored on Task itself, so they can never drift out of sync. */
export function toTaskResponse(task: Task): TaskResponseDto {
  return {
    id: task.id,
    title: task.title,
    description: task.description,
    assigneeEmployeeId: task.assigneeEmployeeId,
    assigneeName: `${task.assignee.firstName} ${task.assignee.lastName}`,
    assigneePhotoUrl: task.assignee.profilePhotoUrl ?? null,
    departmentId: task.assignee.departmentId ?? null,
    departmentName: task.assignee.department?.name ?? null,
    assignedByUserId: task.assignedByUserId,
    assignedByName: task.assignedByName,
    assignedByPhotoUrl: task.assignedByPhotoUrl,
    priority: task.priority,
    dueDate: task.dueDate,
    status: task.status,
    completedAt: task.completedAt?.toISOString() ?? null,
    projectId: task.projectId ?? null,
    createdAt: task.createdAt.toISOString(),
    updatedAt: task.updatedAt.toISOString(),
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
