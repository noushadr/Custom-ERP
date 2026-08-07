import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthenticationModule } from '../authentication/authentication.module';
import { EmployeesService } from './application/employees.service';
import { TypeOrmAuditLogRepository } from './data/repositories/audit-log.repository';
import { TypeOrmDocumentRepository } from './data/repositories/document.repository';
import { TypeOrmEmployeeRepository } from './data/repositories/employee.repository';
import { TypeOrmEducationRecordRepository } from './data/repositories/education-record.repository';
import { TypeOrmSalaryRecordRepository } from './data/repositories/salary-record.repository';
import { EducationRecord } from './domain/entities/education-record.entity';
import { EmployeeAuditLog } from './domain/entities/employee-audit-log.entity';
import { EmployeeDocument } from './domain/entities/employee-document.entity';
import { Employee } from './domain/entities/employee.entity';
import { SalaryRecord } from './domain/entities/salary-record.entity';
import { AUDIT_LOG_REPOSITORY } from './domain/repositories/audit-log-repository.interface';
import { DOCUMENT_REPOSITORY } from './domain/repositories/document-repository.interface';
import { EDUCATION_RECORD_REPOSITORY } from './domain/repositories/education-record-repository.interface';
import { EMPLOYEE_REPOSITORY } from './domain/repositories/employee-repository.interface';
import { SALARY_RECORD_REPOSITORY } from './domain/repositories/salary-record-repository.interface';
import { EmployeesController } from './presentation/employees.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Employee,
      EmployeeDocument,
      EmployeeAuditLog,
      SalaryRecord,
      EducationRecord,
    ]),
    AuthenticationModule,
  ],
  controllers: [EmployeesController],
  providers: [
    EmployeesService,
    { provide: EMPLOYEE_REPOSITORY, useClass: TypeOrmEmployeeRepository },
    { provide: DOCUMENT_REPOSITORY, useClass: TypeOrmDocumentRepository },
    { provide: AUDIT_LOG_REPOSITORY, useClass: TypeOrmAuditLogRepository },
    {
      provide: SALARY_RECORD_REPOSITORY,
      useClass: TypeOrmSalaryRecordRepository,
    },
    {
      provide: EDUCATION_RECORD_REPOSITORY,
      useClass: TypeOrmEducationRecordRepository,
    },
  ],
  exports: [EMPLOYEE_REPOSITORY],
})
export class EmployeeModule {}
