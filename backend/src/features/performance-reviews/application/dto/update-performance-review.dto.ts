import { Type } from 'class-transformer';
import { IsArray, IsOptional, IsString, ValidateNested } from 'class-validator';
import { PerformanceReviewResponseEntryDto } from './performance-review-response-entry.dto';

/** HR/Admin escape hatch to edit a review's responses/comments regardless of
 * its current status. */
export class UpdatePerformanceReviewDto {
  @IsOptional()
  @IsString()
  employeeComments?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PerformanceReviewResponseEntryDto)
  responses?: PerformanceReviewResponseEntryDto[];
}
