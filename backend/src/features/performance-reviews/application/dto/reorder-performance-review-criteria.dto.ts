import { ArrayMinSize, IsArray, IsUUID } from 'class-validator';

export class ReorderPerformanceReviewCriteriaDto {
  /** Every criterion id, in the desired order. */
  @IsArray()
  @ArrayMinSize(1)
  @IsUUID('4', { each: true })
  orderedIds: string[];
}
