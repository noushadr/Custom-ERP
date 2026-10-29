import { IsEnum, IsOptional } from 'class-validator';
import { OverallRating } from '../../domain/enums/overall-rating.enum';

/** The evaluator-supplied, review-level form field — shared by saving a
 * draft, completing a review and the HR/Admin edit. */
export class ReviewFormFieldsDto {
  @IsOptional()
  @IsEnum(OverallRating)
  overallRating?: OverallRating;
}
