import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthenticationModule } from '../authentication/authentication.module';
import { ClientsModule } from '../clients/clients.module';
import { EmployeeModule } from '../employee/employee.module';
import { LeaveModule } from '../leave/leave.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { TasksModule } from '../tasks/tasks.module';
import { AutomationsService } from './application/automations.service';
import { TypeOrmAutomationExecutionHistoryRepository } from './data/repositories/automation-execution-history.repository';
import { TypeOrmAutomationRepository } from './data/repositories/automation.repository';
import { AutomationExecutionHistory } from './domain/entities/automation-execution-history.entity';
import { Automation } from './domain/entities/automation.entity';
import { AUTOMATION_EXECUTION_HISTORY_REPOSITORY } from './domain/repositories/automation-execution-history-repository.interface';
import { AUTOMATION_REPOSITORY } from './domain/repositories/automation-repository.interface';
import { AutomationsController } from './presentation/automations.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([Automation, AutomationExecutionHistory]),
    AuthenticationModule,
    EmployeeModule,
    ClientsModule,
    TasksModule,
    LeaveModule,
    NotificationsModule,
  ],
  controllers: [AutomationsController],
  providers: [
    AutomationsService,
    { provide: AUTOMATION_REPOSITORY, useClass: TypeOrmAutomationRepository },
    {
      provide: AUTOMATION_EXECUTION_HISTORY_REPOSITORY,
      useClass: TypeOrmAutomationExecutionHistoryRepository,
    },
  ],
})
export class AutomationsModule {}
