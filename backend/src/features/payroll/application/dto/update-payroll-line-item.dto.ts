import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsInt,
  Max,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
} from 'class-validator';

/** One line with a reason and an amount: a fine, or a piece of freelance
 * work paid on top of the salary. */
export class FreelanceTaskDto {
  @IsString()
  @IsNotEmpty()
  description: string;

  @IsNumber()
  @Min(0)
  amount: number;
}

export class UpdatePayrollLineItemDto {
  /** Only settable when the target line item is a freelancer's (see
   * `PayrollService.updateLineItem`) — an employee's `baseSalary` is an
   * immutable snapshot from their salary record and can't be edited here. */
  @IsOptional()
  @IsNumber()
  @Min(0)
  baseSalary?: number;

  /** Unpaid absent days (salary / 30 each). */
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(31)
  absentDays?: number;

  /** Advance salary already paid out, taken off this run. */
  @IsOptional()
  @IsNumber()
  @Min(0)
  advanceSalary?: number;

  /** The complete list of fines for this run, replacing the previous
   * list. */
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => FreelanceTaskDto)
  fines?: FreelanceTaskDto[];

  /** The complete list of freelance tasks for this run, replacing the
   * previous list. */
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => FreelanceTaskDto)
  freelanceTasks?: FreelanceTaskDto[];

  @IsOptional()
  @IsString()
  notes?: string;
}
