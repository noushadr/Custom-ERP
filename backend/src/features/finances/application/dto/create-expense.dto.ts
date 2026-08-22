import { IsDateString, IsEnum, IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { ExpenseCategory } from '../../domain/enums/expense-category.enum';

export class CreateExpenseDto {
  @IsEnum(ExpenseCategory)
  category: ExpenseCategory;

  @IsNumber()
  @Min(0)
  amount: number;

  @IsDateString()
  date: string;

  @IsOptional()
  @IsString()
  payeeName?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}
