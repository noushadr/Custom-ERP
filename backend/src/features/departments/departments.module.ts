import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DepartmentsService } from './application/departments.service';
import { TypeOrmDepartmentRepository } from './data/repositories/department.repository';
import { Department } from './domain/entities/department.entity';
import { DEPARTMENT_REPOSITORY } from './domain/repositories/department-repository.interface';
import { DepartmentsController } from './presentation/departments.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Department])],
  controllers: [DepartmentsController],
  providers: [
    DepartmentsService,
    { provide: DEPARTMENT_REPOSITORY, useClass: TypeOrmDepartmentRepository },
  ],
  exports: [DepartmentsService],
})
export class DepartmentsModule {}
