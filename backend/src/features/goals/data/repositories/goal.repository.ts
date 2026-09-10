import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EmployeeGoal } from '../../domain/entities/employee-goal.entity';
import { GoalRepository } from '../../domain/repositories/goal-repository.interface';

@Injectable()
export class TypeOrmGoalRepository implements GoalRepository {
  constructor(
    @InjectRepository(EmployeeGoal)
    private readonly repository: Repository<EmployeeGoal>,
  ) {}

  findAll(): Promise<EmployeeGoal[]> {
    return this.repository.find({
      where: { archived: false },
      relations: { employee: true },
      order: { createdAt: 'DESC' },
    });
  }

  findById(id: string): Promise<EmployeeGoal | null> {
    return this.repository.findOne({
      where: { id },
      relations: { employee: true },
    });
  }

  findByEmployeeId(employeeId: string): Promise<EmployeeGoal[]> {
    return this.repository.find({
      where: { employeeId, archived: false },
      relations: { employee: true },
      order: { createdAt: 'DESC' },
    });
  }

  save(goal: EmployeeGoal): Promise<EmployeeGoal> {
    return this.repository.save(goal);
  }

  saveMany(goals: EmployeeGoal[]): Promise<EmployeeGoal[]> {
    return this.repository.save(goals);
  }
}
