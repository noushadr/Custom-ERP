import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthenticationModule } from '../authentication/authentication.module';
import { ClientsModule } from '../clients/clients.module';
import { EmployeeModule } from '../employee/employee.module';
import { FinancesService } from './application/finances.service';
import { TypeOrmExpenseRepository } from './data/repositories/expense.repository';
import { Expense } from './domain/entities/expense.entity';
import { EXPENSE_REPOSITORY } from './domain/repositories/expense-repository.interface';
import { ExpensesController } from './presentation/expenses.controller';
import { FinancesController } from './presentation/finances.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([Expense]),
    AuthenticationModule,
    ClientsModule,
    EmployeeModule,
  ],
  controllers: [FinancesController, ExpensesController],
  providers: [
    FinancesService,
    { provide: EXPENSE_REPOSITORY, useClass: TypeOrmExpenseRepository },
  ],
})
export class FinancesModule {}
