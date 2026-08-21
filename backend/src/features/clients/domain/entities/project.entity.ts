import {
  Column,
  Entity,
  JoinColumn,
  JoinTable,
  ManyToMany,
  ManyToOne,
} from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Department } from '../../../departments/domain/entities/department.entity';
import { Employee } from '../../../employee/domain/entities/employee.entity';
import { ProjectPaymentStatus } from '../enums/project-payment-status.enum';
import { ProjectStatus } from '../enums/project-status.enum';
import { ProjectType } from '../enums/project-type.enum';
import { Client } from './client.entity';
import { Service } from './service.entity';

/** `netPrice`/`profit` are deliberately not columns here — they're computed
 * from `originalClientPrice`/`deductionRate`/`cost` in the mapper on every
 * read, so they can never drift out of sync if any of those change. */
@Entity('projects')
export class Project extends BaseEntity {
  @Column()
  clientId: string;

  @ManyToOne(() => Client, { eager: true })
  @JoinColumn({ name: 'clientId' })
  client: Client;

  @Column()
  name: string;

  @Column({ type: 'enum', enum: ProjectType })
  type: ProjectType;

  @Column({
    type: 'enum',
    enum: ProjectStatus,
    default: ProjectStatus.ACTIVE,
  })
  status: ProjectStatus;

  @Column({ type: 'date' })
  startDate: string;

  @Column({ type: 'date', nullable: true })
  endDate?: string;

  /** A retainer's next renewal/billing date — plain tracking field, no
   * automated recurrence (that's the future Automations module's job). */
  @Column({ type: 'date', nullable: true })
  renewalDate?: string;

  /** The price charged to the client — the monthly amount for a retainer,
   * the total for a one-time project. */
  @Column({ type: 'numeric', precision: 12, scale: 2 })
  originalClientPrice: string;

  /** Percentage deducted from `originalClientPrice` to get `netPrice`,
   * e.g. "20.00" for 20%. Defaults to the agency-standard 20%, overridable
   * per project. */
  @Column({ type: 'numeric', precision: 5, scale: 2, default: '20.00' })
  deductionRate: string;

  /** Manually entered for now — real cost automation (from payroll/time
   * allocation) is deferred to the Payroll/Finances modules. */
  @Column({ type: 'numeric', precision: 12, scale: 2, default: '0.00' })
  cost: string;

  @Column({ type: 'text', nullable: true })
  notes?: string;

  /** A simple current-state flag, not a per-invoice ledger — a retainer
   * billed monthly only has one status at a time, reset manually by the
   * admin. Finances' "outstanding invoices" is a live snapshot built from
   * this, not a historical reconstruction. */
  @Column({
    type: 'enum',
    enum: ProjectPaymentStatus,
    enumName: 'project_payment_status_enum',
    default: ProjectPaymentStatus.UNPAID,
  })
  paymentStatus: ProjectPaymentStatus;

  /** Only meaningful when `paymentStatus` is PARTIAL — how much of
   * `netPrice` has been paid so far. Manually entered alongside
   * `paymentStatus`, never auto-derived. */
  @Column({ type: 'numeric', precision: 12, scale: 2, default: '0.00' })
  amountPaid: string;

  @ManyToMany(() => Employee, { eager: true })
  @JoinTable({
    name: 'project_assigned_employees',
    joinColumn: { name: 'projectId', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'employeeId', referencedColumnName: 'id' },
  })
  assignedEmployees: Employee[];

  /** "Teams" in the product spec — reuses Department, per this codebase's
   * established "no separate Teams concept" rule. */
  @ManyToMany(() => Department, { eager: true })
  @JoinTable({
    name: 'project_target_departments',
    joinColumn: { name: 'projectId', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'departmentId', referencedColumnName: 'id' },
  })
  targetDepartments: Department[];

  @ManyToMany(() => Service, { eager: true })
  @JoinTable({
    name: 'project_services',
    joinColumn: { name: 'projectId', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'serviceId', referencedColumnName: 'id' },
  })
  services: Service[];
}
