import { Column, Entity } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';

@Entity('departments')
export class Department extends BaseEntity {
  @Column({ unique: true })
  name: string;

  @Column({ nullable: true })
  description?: string;

  /** Employee id of the department head. Not a typed relation to avoid a
   * circular dependency with the employee feature; resolved by id when needed. */
  @Column({ nullable: true })
  headEmployeeId?: string;

  @Column({ default: false })
  isArchived: boolean;
}
