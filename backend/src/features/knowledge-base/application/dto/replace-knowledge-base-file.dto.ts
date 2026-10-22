import { IsOptional, IsString, MinLength } from 'class-validator';

/** The non-file fields of the multipart request that swaps in a new file for
 * an existing file article. */
export class ReplaceKnowledgeBaseFileDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  title?: string;
}
