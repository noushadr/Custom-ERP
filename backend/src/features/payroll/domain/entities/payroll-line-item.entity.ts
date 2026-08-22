import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Employee } from '../../../employee/domain/entities/employee.entity';
import { PayrollRun } from './payroll-run.entity';

/** One row per employee per PayrollRun. `baseSalary` is a snapshot taken
 * at generation time (the employee's SalaryRecord in effect that month) —
 * it never changes afterwards even if the employee's salary is later
 * amended, since this is meant to be exactly what that month's payroll
 * actually paid. `netPay` is deliberately not a column — computed in the
 * mapper from the other six figures on every read, same convention as
 * Project's netPrice/profit. Bonuses/allowances/overtime/deductions/
 * advances/tax are one-off amounts entered directly against this run —
 * there is no recurring-item or loan-ledger concept in V1. `netPay` here
 * is computed the same way, but Project's own pricing fields have since
 * been removed. */
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
  bonuses: string;

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

  @Column({ type: 'text', nullable: true })
  notes?: string | null;
}
