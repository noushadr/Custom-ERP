import { IsDateString, IsEnum, IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { ExpenseCategory } from '../../domain/enums/expense-category.enum';

export class UpdateExpenseDto {
  @IsOptional()
  @IsEnum(ExpenseCategory)
  category?: ExpenseCategory;

  @IsOptional()
  @IsNumber()
  @Min(0)
  amount?: number;

  @IsOptional()
  @IsDateString()
  date?: string;

  @IsOptional()
  @IsString()
  payeeName?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}
