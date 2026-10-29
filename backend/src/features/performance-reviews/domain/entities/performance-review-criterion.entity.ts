import { Column, Entity } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { CriterionResponseType } from '../enums/criterion-response-type.enum';

/** The configurable, company-wide list of review areas HR/Admin maintains —
 * e.g. "Overall Performance" (rating), "Strengths" (text). Mirrors
 * ChecklistTemplateItem: archived rather than hard-deleted once referenced by
 * a review response, so past reviews keep their history intact. */
@Entity('performance_review_criteria')
export class PerformanceReviewCriterion extends BaseEntity {
  @Column()
  name: string;

  @Column({ type: 'enum', enum: CriterionResponseType })
  responseType: CriterionResponseType;

  @Column({ type: 'int' })
  sortOrder: number;

  /** Optional heading this criterion is grouped under on the form, e.g.
   * "Performance Overview". Consecutive criteria sharing a section render
   * together. */
  @Column({ type: 'varchar', nullable: true })
  section?: string | null;

  /** Rating criteria only: also collect a free-text comment next to the
   * rating. */
  @Column({ default: false })
  hasComment: boolean;

  @Column({ default: false })
  isArchived: boolean;
}
