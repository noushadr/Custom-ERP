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

  @Column({ default: false })
  isArchived: boolean;
}
