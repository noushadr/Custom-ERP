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
}
