import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import configuration from './core/config/configuration';
import { validate } from './core/config/env.validation';
import { DatabaseModule } from './core/database/database.module';
import { AuthenticationModule } from './features/authentication/authentication.module';
import { ChecklistsModule } from './features/checklists/checklists.module';
import { ClientsModule } from './features/clients/clients.module';
import { DepartmentsModule } from './features/departments/departments.module';
import { EmployeeModule } from './features/employee/employee.module';
import { HolidaysModule } from './features/holidays/holidays.module';
import { KnowledgeBaseModule } from './features/knowledge-base/knowledge-base.module';
import { LeadsModule } from './features/leads/leads.module';
import { LeaveModule } from './features/leave/leave.module';
import { NoticesModule } from './features/notices/notices.module';
import { NotificationsModule } from './features/notifications/notifications.module';
import { PayrollModule } from './features/payroll/payroll.module';
import { PerformanceReviewsModule } from './features/performance-reviews/performance-reviews.module';
import { RequestsModule } from './features/requests/requests.module';
import { TasksModule } from './features/tasks/tasks.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
      validate,
    }),
    ScheduleModule.forRoot(),
    DatabaseModule,
    AuthenticationModule,
    ChecklistsModule,
    DepartmentsModule,
    EmployeeModule,
    NoticesModule,
    RequestsModule,
    LeaveModule,
    HolidaysModule,
    PerformanceReviewsModule,
    KnowledgeBaseModule,
    TasksModule,
    ClientsModule,
    NotificationsModule,
    PayrollModule,
    LeadsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
