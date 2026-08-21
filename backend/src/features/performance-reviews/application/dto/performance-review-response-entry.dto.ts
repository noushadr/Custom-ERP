import { IsInt, IsOptional, IsString, IsUUID, Max, Min } from 'class-validator';

export class PerformanceReviewResponseEntryDto {
  @IsUUID()
  responseId: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(5)
  ratingValue?: number;

  @IsOptional()
  @IsString()
  textValue?: string;
}
