import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthenticationModule } from '../authentication/authentication.module';
import { DepartmentsModule } from '../departments/departments.module';
import { EmployeeModule } from '../employee/employee.module';
import { HolidaysModule } from '../holidays/holidays.module';
import { LeaveService } from './application/leave.service';
import { TypeOrmLeaveBalanceAdjustmentRepository } from './data/repositories/leave-balance-adjustment.repository';
import { TypeOrmLeaveBalanceRepository } from './data/repositories/leave-balance.repository';
import { TypeOrmLeaveRequestRepository } from './data/repositories/leave-request.repository';
import { TypeOrmLeaveTypeRepository } from './data/repositories/leave-type.repository';
import { LeaveBalanceAdjustment } from './domain/entities/leave-balance-adjustment.entity';
import { LeaveBalance } from './domain/entities/leave-balance.entity';
import { LeaveRequest } from './domain/entities/leave-request.entity';
import { LeaveType } from './domain/entities/leave-type.entity';
import { LEAVE_BALANCE_ADJUSTMENT_REPOSITORY } from './domain/repositories/leave-balance-adjustment-repository.interface';
import { LEAVE_BALANCE_REPOSITORY } from './domain/repositories/leave-balance-repository.interface';
import { LEAVE_REQUEST_REPOSITORY } from './domain/repositories/leave-request-repository.interface';
import { LEAVE_TYPE_REPOSITORY } from './domain/repositories/leave-type-repository.interface';
import { LeaveController } from './presentation/leave.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      LeaveType,
      LeaveBalance,
      LeaveRequest,
      LeaveBalanceAdjustment,
    ]),
    AuthenticationModule,
    DepartmentsModule,
    EmployeeModule,
    HolidaysModule,
  ],
  controllers: [LeaveController],
  providers: [
    LeaveService,
    { provide: LEAVE_TYPE_REPOSITORY, useClass: TypeOrmLeaveTypeRepository },
    {
      provide: LEAVE_BALANCE_REPOSITORY,
      useClass: TypeOrmLeaveBalanceRepository,
    },
    {
      provide: LEAVE_REQUEST_REPOSITORY,
      useClass: TypeOrmLeaveRequestRepository,
    },
    {
      provide: LEAVE_BALANCE_ADJUSTMENT_REPOSITORY,
      useClass: TypeOrmLeaveBalanceAdjustmentRepository,
    },
  ],
})
export class LeaveModule {}
