import { Expense } from '../domain/entities/expense.entity';
import { ExpenseResponseDto } from './finances-response.interface';

export function toExpenseResponse(expense: Expense): ExpenseResponseDto {
  return {
    id: expense.id,
    category: expense.category,
    amount: Number(expense.amount),
    date: expense.date,
    payeeName: expense.payeeName ?? null,
    notes: expense.notes ?? null,
    createdAt: expense.createdAt.toISOString(),
    updatedAt: expense.updatedAt.toISOString(),
  };
}
