import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';
import { KnowledgeBaseVisibility } from '../../domain/enums/knowledge-base-visibility.enum';

export class UpdateKnowledgeBaseArticleDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  title?: string;

  @IsOptional()
  content?: unknown;

  @IsOptional()
  @IsEnum(KnowledgeBaseVisibility)
  visibilityType?: KnowledgeBaseVisibility;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  targetRoleIds?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  targetDepartmentIds?: string[];

  @IsOptional()
  @IsBoolean()
  isArchived?: boolean;
}
