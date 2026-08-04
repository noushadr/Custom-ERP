import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Employee } from '../../domain/entities/employee.entity';
import { EmployeeRepository } from '../../domain/repositories/employee-repository.interface';

@Injectable()
export class TypeOrmEmployeeRepository implements EmployeeRepository {
  constructor(
    @InjectRepository(Employee)
    private readonly repository: Repository<Employee>,
  ) {}

  findAll(): Promise<Employee[]> {
    return this.repository.find({ order: { createdAt: 'ASC' } });
  }

  findById(id: string): Promise<Employee | null> {
    return this.repository.findOne({ where: { id } });
  }

  findByUserId(userId: string): Promise<Employee | null> {
    return this.repository.findOne({ where: { userId } });
  }

  count(): Promise<number> {
    return this.repository.count();
  }

  save(employee: Employee): Promise<Employee> {
    return this.repository.save(employee);
  }
}
