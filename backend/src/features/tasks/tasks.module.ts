import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthenticationModule } from '../authentication/authentication.module';
import { DepartmentsModule } from '../departments/departments.module';
import { EmployeeModule } from '../employee/employee.module';
import { TasksService } from './application/tasks.service';
import { TypeOrmTaskAuditLogRepository } from './data/repositories/task-audit-log.repository';
import { TypeOrmTaskCommentRepository } from './data/repositories/task-comment.repository';
import { TypeOrmTaskRepository } from './data/repositories/task.repository';
import { TaskAuditLog } from './domain/entities/task-audit-log.entity';
import { TaskComment } from './domain/entities/task-comment.entity';
import { Task } from './domain/entities/task.entity';
import { TASK_AUDIT_LOG_REPOSITORY } from './domain/repositories/task-audit-log-repository.interface';
import { TASK_COMMENT_REPOSITORY } from './domain/repositories/task-comment-repository.interface';
import { TASK_REPOSITORY } from './domain/repositories/task-repository.interface';
import { TasksController } from './presentation/tasks.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([Task, TaskComment, TaskAuditLog]),
    AuthenticationModule,
    EmployeeModule,
    DepartmentsModule,
  ],
  controllers: [TasksController],
  providers: [
    TasksService,
    { provide: TASK_REPOSITORY, useClass: TypeOrmTaskRepository },
    {
      provide: TASK_COMMENT_REPOSITORY,
      useClass: TypeOrmTaskCommentRepository,
    },
    {
      provide: TASK_AUDIT_LOG_REPOSITORY,
      useClass: TypeOrmTaskAuditLogRepository,
    },
  ],
  exports: [TasksService],
})
export class TasksModule {}
