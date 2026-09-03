import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Employee } from '../../../employee/domain/entities/employee.entity';
import { Freelancer } from '../../../freelancers/domain/entities/freelancer.entity';
import { PayrollRun } from './payroll-run.entity';

/** One row per employee (or freelancer) per PayrollRun. `baseSalary` is a
 * snapshot taken at generation time (the employee's SalaryRecord in effect
 * that month) — it never changes afterwards even if the employee's salary
 * is later amended, since this is meant to be exactly what that month's
 * payroll actually paid. Deliberately minimal: no attendance/fines
 * tracking of any kind (that granular breakdown was removed 2026-08-26 per
 * explicit instruction and isn't wanted back — this app still has no
 * attendance module). A single `additions`/`deductions` pair was added
 * back 2026-09-03, also per explicit instruction, purely so `netPay` can be
 * justified with a one-line "why" rather than being an opaque directly-
 * entered figure — `netPay` itself is computed in the mapper as
 * `baseSalary + additions - deductions`, not stored. */
@Entity('payroll_line_items')
export class PayrollLineItem extends BaseEntity {
  @Column()
  runId: string;

  @ManyToOne(() => PayrollRun, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'runId' })
  run: PayrollRun;

  /** Exactly one of `employeeId`/`freelancerId` is set per line item —
   * enforced in `PayrollService`, not a DB constraint (see the migration
   * that introduced `freelancerId`). */
  @Column({ type: 'uuid', nullable: true })
  employeeId?: string | null;

  @ManyToOne(() => Employee, { eager: true, nullable: true })
  @JoinColumn({ name: 'employeeId' })
  employee?: Employee | null;

  @Column({ type: 'uuid', nullable: true })
  freelancerId?: string | null;

  @ManyToOne(() => Freelancer, { eager: true, nullable: true })
  @JoinColumn({ name: 'freelancerId' })
  freelancer?: Freelancer | null;

  /** For an employee, the SalaryRecord snapshot taken at generation time
   * (see the class doc above). For a freelancer, there is no salary
   * history to snapshot from — this is instead a plain directly-entered
   * amount, set when they're added to the run and freely editable
   * afterwards while the run is Draft (see `PayrollService.updateLineItem`
   * — it only allows editing `baseSalary` when `freelancerId` is set). */
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

  /** A one-off amount added on top of `baseSalary` this run (bonus,
   * reimbursement, etc.) — freely editable while the run is Draft, defaults
   * to 0. */
  @Column({ type: 'numeric', precision: 12, scale: 2, default: '0.00' })
  additions: string;

  /** A one-off amount subtracted from `baseSalary` this run — freely
   * editable while the run is Draft, defaults to 0. */
  @Column({ type: 'numeric', precision: 12, scale: 2, default: '0.00' })
  deductions: string;

  @Column({ type: 'text', nullable: true })
  notes?: string | null;
}
