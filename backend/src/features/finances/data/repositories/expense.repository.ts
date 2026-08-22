import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Expense } from '../../domain/entities/expense.entity';
import { ExpenseRepository } from '../../domain/repositories/expense-repository.interface';

@Injectable()
export class TypeOrmExpenseRepository implements ExpenseRepository {
  constructor(
    @InjectRepository(Expense)
    private readonly repository: Repository<Expense>,
  ) {}

  findAll(): Promise<Expense[]> {
    return this.repository.find({ order: { date: 'DESC' } });
  }

  findById(id: string): Promise<Expense | null> {
    return this.repository.findOne({ where: { id } });
  }

  save(expense: Expense): Promise<Expense> {
    return this.repository.save(expense);
  }
}
