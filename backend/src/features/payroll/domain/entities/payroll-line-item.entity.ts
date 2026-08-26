import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Employee } from '../../../employee/domain/entities/employee.entity';
import { PayrollRun } from './payroll-run.entity';

/** One row per employee per PayrollRun. `baseSalary` is a snapshot taken
 * at generation time (the employee's SalaryRecord in effect that month) —
 * it never changes afterwards even if the employee's salary is later
 * amended, since this is meant to be exactly what that month's payroll
 * actually paid. `netPay` is deliberately not a column — computed in the
 * mapper from the other figures on every read, same convention as
 * Project's netPrice/profit (since removed). Allowances/overtime/
 * deductions/advances/tax/fines are one-off amounts entered directly
 * against this run — there is no recurring-item or loan-ledger concept in
 * V1. `lateCount` is a plain entered count (no attendance-tracking module
 * exists yet) — every 3 lates deducts one unpaid day's salary, computed
 * in the mapper from `baseSalary` and the run's days-in-month (see
 * `lateDeductionRs` in payroll.mapper.ts), never stored. */
@Entity('payroll_line_items')
export class PayrollLineItem extends BaseEntity {
  @Column()
  runId: string;

  @ManyToOne(() => PayrollRun, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'runId' })
  run: PayrollRun;

  @Column()
  employeeId: string;

  @ManyToOne(() => Employee, { eager: true })
  @JoinColumn({ name: 'employeeId' })
  employee: Employee;

  @Column({ type: 'numeric', precision: 12, scale: 2 })
  baseSalary: string;

  @Column({ type: 'numeric', precision: 12, scale: 2, default: '0.00' })
  allowances: string;

  @Column({ type: 'numeric', precision: 12, scale: 2, default: '0.00' })
  overtime: string;

  @Column({ type: 'numeric', precision: 12, scale: 2, default: '0.00' })
  deductions: string;

  @Column({ type: 'numeric', precision: 12, scale: 2, default: '0.00' })
  advances: string;

  @Column({ type: 'numeric', precision: 12, scale: 2, default: '0.00' })
  tax: string;

  /** One-off fine amount for this run — distinct from the generic
   * `deductions` field so fines are tracked separately. */
  @Column({ type: 'numeric', precision: 12, scale: 2, default: '0.00' })
  fines: string;

  /** Count of late arrivals recorded for this employee this month. Every
   * 3 lates deducts one unpaid day's salary — see `lateDeductionRs` in
   * payroll.mapper.ts. */
  @Column({ type: 'int', default: 0 })
  lateCount: number;

  @Column({ type: 'text', nullable: true })
  notes?: string | null;
}
