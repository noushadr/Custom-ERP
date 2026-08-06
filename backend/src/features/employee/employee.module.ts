import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthenticationModule } from '../authentication/authentication.module';
import { EmployeesService } from './application/employees.service';
import { TypeOrmDocumentRepository } from './data/repositories/document.repository';
import { TypeOrmEmployeeRepository } from './data/repositories/employee.repository';
import { EmployeeDocument } from './domain/entities/employee-document.entity';
import { Employee } from './domain/entities/employee.entity';
import { DOCUMENT_REPOSITORY } from './domain/repositories/document-repository.interface';
import { EMPLOYEE_REPOSITORY } from './domain/repositories/employee-repository.interface';
import { EmployeesController } from './presentation/employees.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([Employee, EmployeeDocument]),
    AuthenticationModule,
  ],
  controllers: [EmployeesController],
  providers: [
    EmployeesService,
    { provide: EMPLOYEE_REPOSITORY, useClass: TypeOrmEmployeeRepository },
    { provide: DOCUMENT_REPOSITORY, useClass: TypeOrmDocumentRepository },
  ],
  exports: [EMPLOYEE_REPOSITORY],
})
export class EmployeeModule {}
