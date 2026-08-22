import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthenticationModule } from '../authentication/authentication.module';
import { EmployeeModule } from '../employee/employee.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PayrollService } from './application/payroll.service';
import { TypeOrmPayrollLineItemRepository } from './data/repositories/payroll-line-item.repository';
import { TypeOrmPayrollRunRepository } from './data/repositories/payroll-run.repository';
import { PayrollLineItem } from './domain/entities/payroll-line-item.entity';
import { PayrollRun } from './domain/entities/payroll-run.entity';
import { PAYROLL_LINE_ITEM_REPOSITORY } from './domain/repositories/payroll-line-item-repository.interface';
import { PAYROLL_RUN_REPOSITORY } from './domain/repositories/payroll-run-repository.interface';
import { PayrollController } from './presentation/payroll.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([PayrollRun, PayrollLineItem]),
    AuthenticationModule,
    EmployeeModule,
    NotificationsModule,
  ],
  controllers: [PayrollController],
  providers: [
    PayrollService,
    { provide: PAYROLL_RUN_REPOSITORY, useClass: TypeOrmPayrollRunRepository },
    {
      provide: PAYROLL_LINE_ITEM_REPOSITORY,
      useClass: TypeOrmPayrollLineItemRepository,
    },
  ],
})
export class PayrollModule {}
