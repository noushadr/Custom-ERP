import { Column, Entity } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';

@Entity('leads')
export class Lead extends BaseEntity {
  @Column({ type: 'date' })
  leadDate: string;

  @Column()
  fullName: string;

  @Column({ nullable: true })
  companyName?: string;

  /** How this lead came in (e.g. "Referral", "LinkedIn", "Cold Call") —
   * free text, same convention as Client.leadSource, since real lead
   * channels vary and new ones show up over time. */
  @Column({ nullable: true })
  leadSource?: string;

  @Column({ nullable: true })
  phone?: string;

  @Column({ nullable: true })
  email?: string;

  @Column({ nullable: true })
  country?: string;

  @Column({ type: 'text', nullable: true })
  remarks?: string;

  /** Free-text service label — deliberately not linked to the Service
   * catalog (SEO, SMM, ...), since a lead's interest is often vague or
   * spans multiple services and shouldn't be blocked on catalog entries. */
  @Column({ nullable: true })
  serviceInterested?: string;
}
