import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Employee } from '../../../employee/domain/entities/employee.entity';
import { PayrollRun } from './payroll-run.entity';

/** One row per employee per PayrollRun. `baseSalary` is a snapshot taken
 * at generation time (the employee's SalaryRecord in effect that month) —
 * it never changes afterwards even if the employee's salary is later
 * amended, since this is meant to be exactly what that month's payroll
 * actually paid. `netPay` (and the "effective" base pay used to compute
 * it) is deliberately not a column — computed in the mapper on every
 * read, same convention as Project's netPrice/profit (since removed).
 * Allowances/overtime/deductions/advances/tax/fines/reimbursement/
 * commissions/totalAbsent/lateHours/lateDays are one-off amounts entered
 * directly against this run — there is no recurring-item or loan-ledger
 * concept in V1, and no attendance-tracking module exists yet (Attendance
 * is still a future module), so absence/lateness are plain entered counts
 * rather than derived from real attendance data. Every rate-based
 * deduction (absence, late hours, late days) uses a flat 30-day month —
 * this app's real payroll process divides by 30 regardless of the actual
 * calendar days in the run's month, so the mapper mirrors that exactly
 * rather than using the real days-in-month. */
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

  /** Piece-rate units delivered this run (e.g. articles/entries) — set
   * together with `perUnitRate` for employees paid per unit rather than a
   * fixed salary. When both are present, `quantity * perUnitRate`
   * replaces the `baseSalary` snapshot as this run's effective base pay
   * (see `toPayrollLineItemResponse`). `null` for salaried employees. */
  @Column({ type: 'int', nullable: true })
  quantity?: number | null;

  @Column({ type: 'numeric', precision: 12, scale: 2, nullable: true })
  perUnitRate?: string | null;

  @Column({ type: 'numeric', precision: 12, scale: 2, default: '0.00' })
  allowances: string;

  @Column({ type: 'numeric', precision: 12, scale: 2, default: '0.00' })
  overtime: string;

  /** One-off addition — reimbursed expenses for this run. */
  @Column({ type: 'numeric', precision: 12, scale: 2, default: '0.00' })
  reimbursement: string;

  /** One-off addition — commissions/incentives for this run. */
  @Column({ type: 'numeric', precision: 12, scale: 2, default: '0.00' })
  commissions: string;

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

  /** Full absence days this month — deducted at the flat daily rate
   * (baseSalary / 30), no threshold. */
  @Column({ type: 'int', default: 0 })
  totalAbsent: number;

  /** Cumulative hours late this month — deducted at the flat hourly rate
   * (baseSalary / 30 / 8), no threshold. Distinct from `lateDays` below;
   * an employee can accrue both in the same run. */
  @Column({ type: 'int', default: 0 })
  lateHours: number;

  /** Count of late-arrival days this month. Every 3 lates deducts one
   * unpaid day's salary — see `lateDaysDeductionRs` in payroll.mapper.ts. */
  @Column({ type: 'int', default: 0 })
  lateDays: number;

  @Column({ type: 'text', nullable: true })
  notes?: string | null;
}
