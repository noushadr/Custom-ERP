import { IsInt, IsNumberString, IsOptional, Max, Min } from 'class-validator';

export class UpdateFinancialRecordDto {
  @IsOptional()
  @IsInt()
  @Min(2000)
  @Max(2100)
  year?: number;

  /** 1-12. */
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(12)
  month?: number;

  @IsOptional()
  @IsNumberString()
  revenueRs?: string;

  @IsOptional()
  @IsNumberString()
  revenueUsd?: string;

  @IsOptional()
  @IsNumberString()
  expenseRs?: string;

  @IsOptional()
  @IsNumberString()
  expenseUsd?: string;

  @IsOptional()
  @IsNumberString()
  fxRate?: string;
}
