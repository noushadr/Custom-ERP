import { IsBoolean, IsEnum, IsOptional, IsString, MinLength } from 'class-validator';
import { CriterionResponseType } from '../../domain/enums/criterion-response-type.enum';

export class UpdatePerformanceReviewCriterionDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  name?: string;

  @IsOptional()
  @IsEnum(CriterionResponseType)
  responseType?: CriterionResponseType;

  @IsOptional()
  @IsBoolean()
  isArchived?: boolean;
}
