import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Employee } from '../../../employee/domain/entities/employee.entity';
import { Freelancer } from '../../../freelancers/domain/entities/freelancer.entity';
import { PayrollRun } from './payroll-run.entity';

/** One row per employee (or freelancer) per PayrollRun. `baseSalary` is a
 * snapshot taken at generation time (the employee's SalaryRecord in effect
 * that month) — it never changes afterwards even if the employee's salary
 * is later amended, since this is meant to be exactly what that month's
 * payroll actually paid. `netPay` is computed in the mapper, never stored:
 * `baseSalary - lateDeduction - lateHoursDeduction - fines + freelance`,
 * where the late deduction is `lateDeductionDays` unpaid days at
 * `baseSalary / 30` (always 30 calendar days) and the late-hours deduction is
 * `lateHours` at `baseSalary / 30 / 8`. `lateDays`/`lateDeductionDays` come from the attendance
 * module and are refreshed by "Sync attendance"; fines and freelance tasks
 * are entered by hand on each row. */
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

  /** Late arrivals counted from attendance for this run's month. */
  @Column({ type: 'int', default: 0 })
  lateDays: number;

  /** Unpaid days earned by those lates (one per 3, or 5 for a Team Lead/HR). */
  @Column({ type: 'int', default: 0 })
  lateDeductionDays: number;

  /** Unpaid days off entered by HR, taken at `baseSalary / 30` each. */
  @Column({ type: 'int', default: 0 })
  absentDays: number;

  /** Salary already paid out in advance, taken off this run. */
  @Column({ type: 'numeric', precision: 12, scale: 2, default: '0.00' })
  advanceSalary: string;

  /** Whole hours cut for arriving after the cut-off, counted from
   * attendance (in hours, e.g. 2.00). Paid at base / 30 / 8 per hour. */
  @Column({ type: 'numeric', precision: 6, scale: 2, default: '0.00' })
  lateHours: string;

  /** Fines taken off this run, each with a reason. */
  @Column({ type: 'jsonb', default: () => "'[]'" })
  fines: { description: string; amount: number }[];

  /** Freelance work done on top of the salary, each with its own charge —
   * added to this run's pay. */
  @Column({ type: 'jsonb', default: () => "'[]'" })
  freelanceTasks: { description: string; amount: number }[];

  @Column({ type: 'text', nullable: true })
  notes?: string | null;
}
