import { IsNumber, IsOptional, IsString, Min, MinLength } from 'class-validator';

export class CreateLeaveTypeDto {
  @IsString()
  @MinLength(2)
  name: string;

  @IsNumber()
  @Min(0)
  annualAllowanceDays: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  carryForwardLimitDays?: number;

  @IsOptional()
  @IsString()
  colorHex?: string;
}
