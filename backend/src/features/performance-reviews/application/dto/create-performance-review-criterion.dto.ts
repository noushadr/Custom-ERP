import { IsEnum, IsString, MinLength } from 'class-validator';
import { CriterionResponseType } from '../../domain/enums/criterion-response-type.enum';

export class CreatePerformanceReviewCriterionDto {
  @IsString()
  @MinLength(2)
  name: string;

  @IsEnum(CriterionResponseType)
  responseType: CriterionResponseType;
}
