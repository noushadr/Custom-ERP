import { Transform } from 'class-transformer';
import { IsArray, IsEnum, IsOptional, IsString, MinLength } from 'class-validator';
import { KnowledgeBaseVisibility } from '../../domain/enums/knowledge-base-visibility.enum';

/** A multipart form field that is sent once comes through as a string and
 * when repeated as an array — normalise both to an array. */
const toStringArray = ({ value }: { value: unknown }): unknown =>
  value === undefined || value === null || value === ''
    ? undefined
    : Array.isArray(value)
      ? value
      : [value];

/** The non-file fields of the multipart request that creates an article from
 * an uploaded file (same title/visibility targeting as a written article). */
export class CreateKnowledgeBaseFileArticleDto {
  @IsString()
  @MinLength(2)
  title: string;

  @IsEnum(KnowledgeBaseVisibility)
  visibilityType: KnowledgeBaseVisibility;

  @IsOptional()
  @Transform(toStringArray)
  @IsArray()
  @IsString({ each: true })
  targetRoleIds?: string[];

  @IsOptional()
  @Transform(toStringArray)
  @IsArray()
  @IsString({ each: true })
  targetDepartmentIds?: string[];
}
