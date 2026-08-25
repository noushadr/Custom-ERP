import { IsInt, IsNumberString, Max, Min } from 'class-validator';

export class CreateFinancialRecordDto {
  @IsInt()
  @Min(2000)
  @Max(2100)
  year: number;

  /** 1-12. */
  @IsInt()
  @Min(1)
  @Max(12)
  month: number;

  @IsNumberString()
  revenueRs: string;

  @IsNumberString()
  revenueUsd: string;

  @IsNumberString()
  expenseRs: string;

  @IsNumberString()
  expenseUsd: string;

  @IsNumberString()
  fxRate: string;
}
