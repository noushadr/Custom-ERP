import { PerformanceReviewCriterion } from '../entities/performance-review-criterion.entity';

export const PERFORMANCE_REVIEW_CRITERION_REPOSITORY = Symbol(
  'PERFORMANCE_REVIEW_CRITERION_REPOSITORY',
);

export interface PerformanceReviewCriterionRepository {
  findAll(includeArchived?: boolean): Promise<PerformanceReviewCriterion[]>;
  findById(id: string): Promise<PerformanceReviewCriterion | null>;
  findByIds(ids: string[]): Promise<PerformanceReviewCriterion[]>;
  save(item: PerformanceReviewCriterion): Promise<PerformanceReviewCriterion>;
  saveMany(
    items: PerformanceReviewCriterion[],
  ): Promise<PerformanceReviewCriterion[]>;
  remove(item: PerformanceReviewCriterion): Promise<void>;
}
