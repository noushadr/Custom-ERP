import { IsIn, IsInt, IsOptional, IsUUID, Min } from 'class-validator';

export class CreatePerformanceReviewDto {
  @IsUUID()
  employeeId: string;

  @IsInt()
  @Min(1)
  reviewYear: number;

  /** 1 = June, 2 = December; defaults to the cycle for the current month. */
  @IsOptional()
  @IsIn([1, 2])
  reviewPeriod?: number;
}
