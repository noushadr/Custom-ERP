import { IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class UpdatePayrollLineItemDto {
  @IsOptional()
  @IsNumber()
  @Min(0)
  bonuses?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  allowances?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  overtime?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  deductions?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  advances?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  tax?: number;

  @IsOptional()
  @IsString()
  notes?: string;
}
