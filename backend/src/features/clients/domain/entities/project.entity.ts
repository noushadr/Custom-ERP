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
import { ProjectStatus } from '../enums/project-status.enum';
import { ProjectType } from '../enums/project-type.enum';
import { Client } from './client.entity';
import { Service } from './service.entity';

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

  /** A retainer's next renewal/billing date. */
  @Column({ type: 'date', nullable: true })
  renewalDate?: string;

  @Column({ type: 'text', nullable: true })
  notes?: string;

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
