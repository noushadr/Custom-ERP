import { Inject, Injectable } from '@nestjs/common';
import { Department } from '../domain/entities/department.entity';
import {
  DEPARTMENT_REPOSITORY,
  type DepartmentRepository,
} from '../domain/repositories/department-repository.interface';
import { CreateDepartmentDto } from './dto/create-department.dto';

@Injectable()
export class DepartmentsService {
  constructor(
    @Inject(DEPARTMENT_REPOSITORY)
    private readonly departmentRepository: DepartmentRepository,
  ) {}

  findAll(): Promise<Department[]> {
    return this.departmentRepository.findAll();
  }

  create(dto: CreateDepartmentDto): Promise<Department> {
    const department = new Department();
    department.name = dto.name;
    department.description = dto.description;
    department.headEmployeeId = dto.headEmployeeId;
    return this.departmentRepository.save(department);
  }
}
