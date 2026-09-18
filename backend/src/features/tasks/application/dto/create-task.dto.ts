import {
  IsDateString,
  IsEnum,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';
import { TaskPriority } from '../../domain/enums/task-priority.enum';

export class CreateTaskDto {
  @IsString()
  @MinLength(2)
  title: string;

  @IsOptional()
  @IsString()
  description?: string;

  /** Exactly one of [assigneeEmployeeId]/[departmentId] should be set —
   * `TasksService.createTask` requires it and 400s otherwise. Assigning to
   * a specific employee still needs the usual create authority (override or
   * heading their department); assigning to a team alone needs none — any
   * authenticated employee can hand a task to a team, per explicit
   * instruction, leaving the team to pick who actually does it. */
  @IsOptional()
  @IsString()
  assigneeEmployeeId?: string;

  @IsOptional()
  @IsString()
  departmentId?: string;

  @IsOptional()
  @IsEnum(TaskPriority)
  priority?: TaskPriority;

  @IsDateString()
  dueDate: string;

  /** Optional link to a Clients & Projects project — gated by the same
   * create authority as the rest of this DTO (override or dept-head of the
   * assignee's department), not a separate clients.manage check. */
  @IsOptional()
  @IsString()
  projectId?: string;
}
