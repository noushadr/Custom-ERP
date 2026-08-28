import { Column, Entity, Unique } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';

/** One row per calendar month (never a fiscal year — deliberately plain
 * Jan-Dec, per explicit instruction when this module was built, even
 * though the source spreadsheet it was seeded from was organized by
 * fiscal year Jul-Jun). `profitRs`/`profitUsd`/`profitPercent` are not
 * columns — computed in the mapper from revenue/expense on every read,
 * same convention as PayrollLineItem's netPay. */
@Entity('financial_records')
@Unique('UQ_financial_records_year_month', ['year', 'month'])
export class FinancialRecord extends BaseEntity {
  @Column({ type: 'int' })
  year: number;

  /** 1-12. */
  @Column({ type: 'int' })
  month: number;

  @Column({ type: 'numeric', precision: 14, scale: 2 })
  revenueRs: string;

  @Column({ type: 'numeric', precision: 14, scale: 2 })
  revenueUsd: string;

  @Column({ type: 'numeric', precision: 14, scale: 2 })
  expenseRs: string;

  @Column({ type: 'numeric', precision: 14, scale: 2 })
  expenseUsd: string;

  /** PKR-per-USD rate for the month, kept only for reference/display —
   * revenue/expense in both currencies are entered directly rather than
   * derived from this rate, since the source figures don't always convert
   * at a single clean rate (banking/platform fees vary). */
  @Column({ type: 'numeric', precision: 8, scale: 2 })
  fxRate: string;
}
