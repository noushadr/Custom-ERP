import { IsInt, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class UpdatePayrollLineItemDto {
  /** Only settable when the target line item is a freelancer's (see
   * `PayrollService.updateLineItem`) — an employee's `baseSalary` is an
   * immutable snapshot from their salary record and can't be edited here. */
  @IsOptional()
  @IsNumber()
  @Min(0)
  baseSalary?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  quantity?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  perUnitRate?: number;

  /** What was actually paid — freely editable for every line item. */
  @IsOptional()
  @IsNumber()
  @Min(0)
  netPay?: number;

  @IsOptional()
  @IsString()
  notes?: string;
}
