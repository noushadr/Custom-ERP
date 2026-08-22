import { PerformanceReviewResponse } from '../entities/performance-review-response.entity';

export const PERFORMANCE_REVIEW_RESPONSE_REPOSITORY = Symbol(
  'PERFORMANCE_REVIEW_RESPONSE_REPOSITORY',
);

export interface PerformanceReviewResponseRepository {
  findByReviewId(
    performanceReviewId: string,
  ): Promise<PerformanceReviewResponse[]>;
  save(item: PerformanceReviewResponse): Promise<PerformanceReviewResponse>;
  saveMany(
    items: PerformanceReviewResponse[],
  ): Promise<PerformanceReviewResponse[]>;
}
