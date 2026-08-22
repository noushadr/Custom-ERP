import { Column, Entity, Unique } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { PayrollRunStatus } from '../enums/payroll-run-status.enum';

/** One row per calendar month a payroll was generated for — never
 * duplicated (see the (month, year) unique constraint). Line items are
 * generated once, then edited only while status is DRAFT. */
@Entity('payroll_runs')
@Unique('UQ_payroll_runs_month_year', ['month', 'year'])
export class PayrollRun extends BaseEntity {
  /** 1-12. */
  @Column({ type: 'int' })
  month: number;

  @Column({ type: 'int' })
  year: number;

  @Column({
    type: 'enum',
    enum: PayrollRunStatus,
    enumName: 'payroll_run_status_enum',
    default: PayrollRunStatus.DRAFT,
  })
  status: PayrollRunStatus;

  @Column()
  generatedByName: string;

  @Column({ type: 'varchar', nullable: true })
  finalizedByName?: string | null;

  @Column({ type: 'timestamptz', nullable: true })
  finalizedAt?: Date | null;

  @Column({ type: 'varchar', nullable: true })
  paidByName?: string | null;

  @Column({ type: 'timestamptz', nullable: true })
  paidAt?: Date | null;
}
