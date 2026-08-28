import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Employee } from '../../../employee/domain/entities/employee.entity';
import { Freelancer } from '../../../freelancers/domain/entities/freelancer.entity';
import { PayrollRun } from './payroll-run.entity';

/** One row per employee (or freelancer) per PayrollRun. `baseSalary` is a
 * snapshot taken at generation time (the employee's SalaryRecord in effect
 * that month) — it never changes afterwards even if the employee's salary
 * is later amended, since this is meant to be exactly what that month's
 * payroll actually paid. Deliberately minimal: no deductions/fines/
 * attendance tracking of any kind (removed 2026-08-26 per explicit
 * instruction — "get rid of all the deductions, fines, absents etc." —
 * this app has no attendance module, and the granular breakdown wasn't
 * wanted). `netPay` is a plain, directly-entered figure — defaults to
 * `baseSalary` when the line item is created, then freely editable for
 * every line item (not just freelancers') while the run is Draft. */
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

  /** What was actually paid — plain and directly entered, not computed
   * from any deduction/addition breakdown. Defaults to `baseSalary` at
   * creation. */
  @Column({ type: 'numeric', precision: 12, scale: 2 })
  netPay: string;

  @Column({ type: 'text', nullable: true })
  notes?: string | null;
}
