import { Column, Entity } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';

/** A lightweight roster of freelance/contract workers paid through Payroll
 * but not full Employee records — no company email, department, or RBAC
 * account, since freelancers don't log into the ERP. Deactivate rather
 * than delete once no longer engaged, same archive-not-delete convention
 * as Service/LeaveType. */
@Entity('freelancers')
export class Freelancer extends BaseEntity {
  @Column()
  fullName: string;

  /** Free-text description of what they do (e.g. "Content Writer") —
   * deliberately not a Department/designation relation, since freelancers
   * sit outside Employee Management entirely. */
  @Column({ type: 'varchar', nullable: true })
  role?: string | null;

  @Column({ type: 'text', nullable: true })
  notes?: string | null;

  @Column({ default: true })
  isActive: boolean;
}
