import { IsDateString, IsEnum, IsOptional, IsString } from 'class-validator';
import { TaskStatus } from '../../domain/enums/task-status.enum';

/** The assignee's own self-service update — broader than the old
 * status-only DTO it replaces, since the assignee can now also move the
 * due date and leave progress remarks, not just change status. Every field
 * is optional; `TasksService.updateProgress` only touches what's actually
 * sent and audit-logs each changed field individually. */
export class UpdateTaskProgressDto {
  @IsOptional()
  @IsEnum(TaskStatus)
  status?: TaskStatus;

  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @IsOptional()
  @IsString()
  progressRemarks?: string;
}
