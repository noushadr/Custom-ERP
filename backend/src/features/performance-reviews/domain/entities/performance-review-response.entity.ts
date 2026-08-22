import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { CriterionResponseType } from '../enums/criterion-response-type.enum';
import { PerformanceReviewCriterion } from './performance-review-criterion.entity';
import { PerformanceReview } from './performance-review.entity';

/** One criterion's response within a specific review. `criterionName`/
 * `responseType`/`sortOrder` are snapshotted from the template at creation
 * time — exactly like EmployeeChecklistItem — so later criteria edits never
 * retroactively change an in-progress or completed review. */
@Entity('performance_review_responses')
export class PerformanceReviewResponse extends BaseEntity {
  @Column()
  performanceReviewId: string;

  @ManyToOne(() => PerformanceReview, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'performanceReviewId' })
  performanceReview: PerformanceReview;

  @Column({ nullable: true })
  criterionId?: string;

  @ManyToOne(() => PerformanceReviewCriterion)
  @JoinColumn({ name: 'criterionId' })
  criterion?: PerformanceReviewCriterion;

  @Column()
  criterionName: string;

  @Column({ type: 'enum', enum: CriterionResponseType })
  responseType: CriterionResponseType;

  @Column({ type: 'int' })
  sortOrder: number;

  @Column({ type: 'int', nullable: true })
  ratingValue?: number;

  @Column({ type: 'text', nullable: true })
  textValue?: string;
}
