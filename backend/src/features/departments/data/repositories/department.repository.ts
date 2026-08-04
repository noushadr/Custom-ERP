import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Department } from '../../domain/entities/department.entity';
import { DepartmentRepository } from '../../domain/repositories/department-repository.interface';

@Injectable()
export class TypeOrmDepartmentRepository implements DepartmentRepository {
  constructor(
    @InjectRepository(Department)
    private readonly repository: Repository<Department>,
  ) {}

  findAll(): Promise<Department[]> {
    return this.repository.find({ order: { name: 'ASC' } });
  }

  findById(id: string): Promise<Department | null> {
    return this.repository.findOne({ where: { id } });
  }

  save(department: Department): Promise<Department> {
    return this.repository.save(department);
  }
}
