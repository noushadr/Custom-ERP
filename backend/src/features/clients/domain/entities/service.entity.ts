import { Column, Entity } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';

/** Admin-managed catalog of service offerings (e.g. "SEO", "Web
 * Development") assignable to projects — same archive-not-delete
 * convention as LeaveType. */
@Entity('services')
export class Service extends BaseEntity {
  @Column({ unique: true })
  name: string;

  @Column({ nullable: true })
  description?: string;

  @Column({ default: false })
  isArchived: boolean;
}
