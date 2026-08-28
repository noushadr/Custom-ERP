import { Type } from 'class-transformer';
import { IsArray, ValidateNested } from 'class-validator';
import { PerformanceReviewResponseEntryDto } from './performance-review-response-entry.dto';

export class CompletePerformanceReviewDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PerformanceReviewResponseEntryDto)
  responses: PerformanceReviewResponseEntryDto[];
}
