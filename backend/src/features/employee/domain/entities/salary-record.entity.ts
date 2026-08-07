import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Employee } from './employee.entity';

@Entity('employee_salary_records')
export class SalaryRecord extends BaseEntity {
  @Column()
  employeeId: string;

  @ManyToOne(() => Employee, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'employeeId' })
  employee: Employee;

  @Column({ type: 'numeric', precision: 12, scale: 2 })
  amount: string;

  /** The date this amount took effect — the earliest record is the joining
   * salary, the most recent is the current salary. */
  @Column({ type: 'date' })
  effectiveDate: string;

  @Column({ nullable: true })
  note?: string;
}
