import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PerformanceReviewResponse } from '../../domain/entities/performance-review-response.entity';
import { PerformanceReviewResponseRepository } from '../../domain/repositories/performance-review-response-repository.interface';

@Injectable()
export class TypeOrmPerformanceReviewResponseRepository
  implements PerformanceReviewResponseRepository
{
  constructor(
    @InjectRepository(PerformanceReviewResponse)
    private readonly repository: Repository<PerformanceReviewResponse>,
  ) {}

  findByReviewId(
    performanceReviewId: string,
  ): Promise<PerformanceReviewResponse[]> {
    return this.repository.find({
      where: { performanceReviewId },
      order: { sortOrder: 'ASC' },
    });
  }

  save(
    item: PerformanceReviewResponse,
  ): Promise<PerformanceReviewResponse> {
    return this.repository.save(item);
  }

  saveMany(
    items: PerformanceReviewResponse[],
  ): Promise<PerformanceReviewResponse[]> {
    return this.repository.save(items);
  }
}
