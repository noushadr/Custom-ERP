import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PerformanceReview } from '../../domain/entities/performance-review.entity';
import { PerformanceReviewStatus } from '../../domain/enums/performance-review-status.enum';
import { PerformanceReviewRepository } from '../../domain/repositories/performance-review-repository.interface';

@Injectable()
export class TypeOrmPerformanceReviewRepository
  implements PerformanceReviewRepository
{
  constructor(
    @InjectRepository(PerformanceReview)
    private readonly repository: Repository<PerformanceReview>,
  ) {}

  findByEmployeeId(employeeId: string): Promise<PerformanceReview[]> {
    return this.repository.find({
      where: { employeeId },
      relations: { employee: true, responses: true },
      order: { reviewYear: 'ASC' },
    });
  }

  findByEmployeeAndYear(
    employeeId: string,
    reviewYear: number,
  ): Promise<PerformanceReview | null> {
    return this.repository.findOne({
      where: { employeeId, reviewYear },
    });
  }

  findById(id: string): Promise<PerformanceReview | null> {
    return this.repository.findOne({
      where: { id },
      relations: { employee: true, responses: true },
    });
  }

  findByStatus(status: PerformanceReviewStatus): Promise<PerformanceReview[]> {
    return this.repository.find({
      where: { status },
      relations: { employee: true, responses: true },
      order: { dueDate: 'ASC' },
    });
  }

  findLatestPerEmployee(): Promise<PerformanceReview[]> {
    return this.repository
      .createQueryBuilder('review')
      .distinctOn(['review.employeeId'])
      .orderBy('review.employeeId', 'ASC')
      .addOrderBy('review.reviewYear', 'DESC')
      .getMany();
  }

  countPendingAsOf(cutoff: Date): Promise<number> {
    return this.repository
      .createQueryBuilder('review')
      .where('review.createdAt <= :cutoff', { cutoff })
      .andWhere(
        '(review.completedAt IS NULL OR review.completedAt > :cutoff)',
        { cutoff },
      )
      .getCount();
  }

  save(review: PerformanceReview): Promise<PerformanceReview> {
    return this.repository.save(review);
  }
}
