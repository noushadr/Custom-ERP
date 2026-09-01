import { PerformanceReview } from '../entities/performance-review.entity';
import { PerformanceReviewStatus } from '../enums/performance-review-status.enum';

export const PERFORMANCE_REVIEW_REPOSITORY = Symbol(
  'PERFORMANCE_REVIEW_REPOSITORY',
);

export interface PerformanceReviewRepository {
  findByEmployeeId(employeeId: string): Promise<PerformanceReview[]>;
  findByEmployeeAndYear(
    employeeId: string,
    reviewYear: number,
  ): Promise<PerformanceReview | null>;
  findById(id: string): Promise<PerformanceReview | null>;
  findByStatus(status: PerformanceReviewStatus): Promise<PerformanceReview[]>;

  /** One row per employee — their highest `reviewYear` review (pending,
   * completed, or finalized). No `employee`/`responses` relations loaded;
   * callers that only need status/dates (e.g. a directory-list summary)
   * shouldn't pay for a full snapshot join per employee. */
  findLatestPerEmployee(): Promise<PerformanceReview[]>;

  /** Count of reviews that were still pending as of [cutoff]: created on or
   * before it, and either never completed or completed after it. Lets a
   * caller compute a "pending count N days ago" baseline without a separate
   * snapshot table — `completedAt` is a one-way marker (a review never goes
   * back to pending once set), so this is exact, not an approximation. */
  countPendingAsOf(cutoff: Date): Promise<number>;

  save(review: PerformanceReview): Promise<PerformanceReview>;
}
