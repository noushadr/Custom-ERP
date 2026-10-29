import { Type } from 'class-transformer';
import { IsArray, ValidateNested } from 'class-validator';
import { PerformanceReviewResponseEntryDto } from './performance-review-response-entry.dto';
import { ReviewFormFieldsDto } from './review-form-fields.dto';

export class CompletePerformanceReviewDto extends ReviewFormFieldsDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PerformanceReviewResponseEntryDto)
  responses: PerformanceReviewResponseEntryDto[];
}
