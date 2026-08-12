import {
  IsBoolean,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  MinLength,
} from 'class-validator';

export class UpdateLeaveTypeDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  name?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  annualAllowanceDays?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  carryForwardLimitDays?: number;

  @IsOptional()
  @IsString()
  colorHex?: string;

  @IsOptional()
  @IsBoolean()
  isArchived?: boolean;
}
