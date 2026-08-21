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

  @IsString()
  assigneeEmployeeId: string;

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
