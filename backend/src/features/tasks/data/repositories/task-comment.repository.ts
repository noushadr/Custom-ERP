import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TaskComment } from '../../domain/entities/task-comment.entity';
import { TaskCommentRepository } from '../../domain/repositories/task-comment-repository.interface';

@Injectable()
export class TypeOrmTaskCommentRepository implements TaskCommentRepository {
  constructor(
    @InjectRepository(TaskComment)
    private readonly repository: Repository<TaskComment>,
  ) {}

  findByTaskId(taskId: string): Promise<TaskComment[]> {
    return this.repository.find({
      where: { taskId },
      order: { createdAt: 'ASC' },
    });
  }

  save(comment: TaskComment): Promise<TaskComment> {
    return this.repository.save(comment);
  }

  async countByTaskIds(taskIds: string[]): Promise<Map<string, number>> {
    if (taskIds.length === 0) return new Map();
    const rows = await this.repository
      .createQueryBuilder('comment')
      .select('comment.taskId', 'taskId')
      .addSelect('COUNT(*)', 'count')
      .where('comment.taskId IN (:...taskIds)', { taskIds })
      .groupBy('comment.taskId')
      .getRawMany<{ taskId: string; count: string }>();
    return new Map(rows.map((row) => [row.taskId, Number(row.count)]));
  }
}
