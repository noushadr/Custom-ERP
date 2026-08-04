import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Department } from '../../../departments/domain/entities/department.entity';

@Entity('teams')
export class Team extends BaseEntity {
  @Column()
  name: string;

  @Column()
  departmentId: string;

  @ManyToOne(() => Department, { eager: true })
  @JoinColumn({ name: 'departmentId' })
  department: Department;

  /** Employee id of the team lead. Not a typed relation, see Department.headEmployeeId. */
  @Column({ nullable: true })
  leadEmployeeId?: string;
}
