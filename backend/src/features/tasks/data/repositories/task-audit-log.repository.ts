import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TaskAuditLog } from '../../domain/entities/task-audit-log.entity';
import { TaskAuditLogRepository } from '../../domain/repositories/task-audit-log-repository.interface';

@Injectable()
export class TypeOrmTaskAuditLogRepository implements TaskAuditLogRepository {
  constructor(
    @InjectRepository(TaskAuditLog)
    private readonly repository: Repository<TaskAuditLog>,
  ) {}

  findByTaskId(taskId: string): Promise<TaskAuditLog[]> {
    return this.repository.find({
      where: { taskId },
      order: { createdAt: 'ASC' },
    });
  }

  save(log: TaskAuditLog): Promise<TaskAuditLog> {
    return this.repository.save(log);
  }
}
