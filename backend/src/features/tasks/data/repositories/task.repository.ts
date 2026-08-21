import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Task } from '../../domain/entities/task.entity';
import { TaskRepository } from '../../domain/repositories/task-repository.interface';

@Injectable()
export class TypeOrmTaskRepository implements TaskRepository {
  constructor(
    @InjectRepository(Task)
    private readonly repository: Repository<Task>,
  ) {}

  findAll(): Promise<Task[]> {
    return this.repository.find({ order: { dueDate: 'ASC' } });
  }

  findById(id: string): Promise<Task | null> {
    return this.repository.findOne({ where: { id } });
  }

  save(task: Task): Promise<Task> {
    return this.repository.save(task);
  }
}
