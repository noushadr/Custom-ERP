import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthenticationModule } from '../authentication/authentication.module';
import { EmployeesService } from './application/employees.service';
import { TypeOrmEmployeeRepository } from './data/repositories/employee.repository';
import { Employee } from './domain/entities/employee.entity';
import { EMPLOYEE_REPOSITORY } from './domain/repositories/employee-repository.interface';
import { EmployeesController } from './presentation/employees.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Employee]), AuthenticationModule],
  controllers: [EmployeesController],
  providers: [
    EmployeesService,
    { provide: EMPLOYEE_REPOSITORY, useClass: TypeOrmEmployeeRepository },
  ],
  exports: [EMPLOYEE_REPOSITORY],
})
export class EmployeeModule {}
