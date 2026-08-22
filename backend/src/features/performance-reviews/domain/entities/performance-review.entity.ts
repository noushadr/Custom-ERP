import { Column, Entity, JoinColumn, ManyToOne, OneToMany } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Employee } from '../../../employee/domain/entities/employee.entity';
import { PerformanceReviewStatus } from '../enums/performance-review-status.enum';
import { PerformanceReviewResponse } from './performance-review-response.entity';

/** One review instance for one employee for one year of service (e.g. "Year
 * 2 Review"). Unique per (employeeId, reviewYear) — the year-by-year history
 * is simply every row for an employeeId, ordered by reviewYear. */
@Entity('performance_reviews')
export class PerformanceReview extends BaseEntity {
  @Column()
  employeeId: string;

  @ManyToOne(() => Employee, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'employeeId' })
  employee: Employee;

  @Column({ type: 'int' })
  reviewYear: number;

  @Column({ type: 'date' })
  dueDate: string;

  @Column({
    type: 'enum',
    enum: PerformanceReviewStatus,
    default: PerformanceReviewStatus.PENDING,
  })
  status: PerformanceReviewStatus;

  @OneToMany(() => PerformanceReviewResponse, (r) => r.performanceReview)
  responses: PerformanceReviewResponse[];

  /** Optional self-assessment the employee may add themselves, any time
   * before the review is finalized. */
  @Column({ type: 'text', nullable: true })
  employeeComments?: string;

  @Column({ nullable: true })
  completedByUserId?: string;

  @Column({ nullable: true })
  completedByName?: string;

  @Column({ type: 'timestamptz', nullable: true })
  completedAt?: Date;

  /** True if whoever completed this was the employee's actual reporting
   * manager; false if an HR/Admin override was used instead — kept distinct
   * so audit/reporting can tell the two apart. */
  @Column({ type: 'boolean', nullable: true })
  completedAsManager?: boolean;

  /** Cleared back to null by `unfinalizeReview` — a `| null` union (not just
   * optional) so TypeORM's `save()` actually nulls the column out, rather
   * than leaving stale finalizer info once a review is un-finalized. */
  @Column({ type: 'varchar', nullable: true })
  finalizedByUserId?: string | null;

  @Column({ type: 'varchar', nullable: true })
  finalizedByName?: string | null;

  @Column({ type: 'timestamptz', nullable: true })
  finalizedAt?: Date | null;
}
