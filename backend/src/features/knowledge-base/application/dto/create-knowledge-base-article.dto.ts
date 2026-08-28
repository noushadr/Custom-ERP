import {
  IsArray,
  IsDefined,
  IsEnum,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';
import { KnowledgeBaseVisibility } from '../../domain/enums/knowledge-base-visibility.enum';

export class CreateKnowledgeBaseArticleDto {
  @IsString()
  @MinLength(2)
  title: string;

  /** A Quill Delta (array of ops) — its internal shape is the editor's
   * concern, not the backend's, so it's stored verbatim rather than
   * structurally validated here. */
  @IsDefined()
  content: unknown;

  @IsEnum(KnowledgeBaseVisibility)
  visibilityType: KnowledgeBaseVisibility;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  targetRoleIds?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  targetDepartmentIds?: string[];
}
