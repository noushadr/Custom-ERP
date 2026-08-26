import { IsInt, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class UpdatePayrollLineItemDto {
  /** Only settable when the target line item is a freelancer's (see
   * `PayrollService.updateLineItem`) — an employee's `baseSalary` is an
   * immutable snapshot from their SalaryRecord and can't be edited here. */
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
  reimbursement?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  commissions?: number;

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
  @IsNumber()
  @Min(0)
  fines?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  totalAbsent?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  lateHours?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  lateDays?: number;

  @IsOptional()
  @IsString()
  notes?: string;
}
