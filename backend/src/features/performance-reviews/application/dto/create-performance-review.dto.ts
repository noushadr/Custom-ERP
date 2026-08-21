import { IsInt, IsUUID, Min } from 'class-validator';

export class CreatePerformanceReviewDto {
  @IsUUID()
  employeeId: string;

  @IsInt()
  @Min(1)
  reviewYear: number;
}
