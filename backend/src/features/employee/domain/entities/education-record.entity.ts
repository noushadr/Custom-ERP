import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Employee } from './employee.entity';

@Entity('employee_education_records')
export class EducationRecord extends BaseEntity {
  @Column()
  employeeId: string;

  @ManyToOne(() => Employee, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'employeeId' })
  employee: Employee;

  @Column()
  degree: string;

  @Column()
  institution: string;

  @Column({ type: 'int' })
  yearCompleted: number;
}
