import { IsEnum, IsOptional, IsString, MinLength } from 'class-validator';
import { WorkMode } from '../../../employee/domain/enums/work-mode.enum';
import { ChecklistType } from '../../domain/enums/checklist-type.enum';

export class CreateChecklistTemplateItemDto {
  @IsEnum(ChecklistType)
  type: ChecklistType;

  @IsString()
  @MinLength(2)
  title: string;

  @IsOptional()
  @IsString()
  description?: string;

  /** Omit (or null) to apply to every employee regardless of work mode. */
  @IsOptional()
  @IsEnum(WorkMode)
  appliesToWorkMode?: WorkMode | null;
}
