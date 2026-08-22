import { Expense } from '../entities/expense.entity';

export const EXPENSE_REPOSITORY = Symbol('EXPENSE_REPOSITORY');

export interface ExpenseRepository {
  findAll(): Promise<Expense[]>;
  findById(id: string): Promise<Expense | null>;
  save(expense: Expense): Promise<Expense>;
}
