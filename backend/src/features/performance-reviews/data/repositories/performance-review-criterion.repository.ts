import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { PerformanceReviewCriterion } from '../../domain/entities/performance-review-criterion.entity';
import { PerformanceReviewCriterionRepository } from '../../domain/repositories/performance-review-criterion-repository.interface';

@Injectable()
export class TypeOrmPerformanceReviewCriterionRepository
  implements PerformanceReviewCriterionRepository
{
  constructor(
    @InjectRepository(PerformanceReviewCriterion)
    private readonly repository: Repository<PerformanceReviewCriterion>,
  ) {}

  findAll(includeArchived = false): Promise<PerformanceReviewCriterion[]> {
    return this.repository.find({
      where: includeArchived ? {} : { isArchived: false },
      order: { sortOrder: 'ASC' },
    });
  }

  findById(id: string): Promise<PerformanceReviewCriterion | null> {
    return this.repository.findOne({ where: { id } });
  }

  findByIds(ids: string[]): Promise<PerformanceReviewCriterion[]> {
    if (ids.length === 0) return Promise.resolve([]);
    return this.repository.find({ where: { id: In(ids) } });
  }

  save(
    item: PerformanceReviewCriterion,
  ): Promise<PerformanceReviewCriterion> {
    return this.repository.save(item);
  }

  saveMany(
    items: PerformanceReviewCriterion[],
  ): Promise<PerformanceReviewCriterion[]> {
    return this.repository.save(items);
  }

  async remove(item: PerformanceReviewCriterion): Promise<void> {
    await this.repository.remove(item);
  }
}
