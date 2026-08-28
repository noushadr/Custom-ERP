import {
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';
import { WorkMode } from '../../../employee/domain/enums/work-mode.enum';

export class UpdateChecklistTemplateItemDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  title?: string;

  @IsOptional()
  @IsString()
  description?: string;

  /** Omit to leave unchanged; send null to clear back to "everyone". */
  @IsOptional()
  @IsEnum(WorkMode)
  appliesToWorkMode?: WorkMode | null;

  @IsOptional()
  @IsBoolean()
  isArchived?: boolean;
}
