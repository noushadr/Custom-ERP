import { Column, Entity } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { ClientHealthStatus } from '../enums/client-health-status.enum';

/** A single primary contact per client is enough for v1 — a separate
 * multi-contact entity can be added later if needed. */
@Entity('clients')
export class Client extends BaseEntity {
  @Column()
  companyName: string;

  @Column({ nullable: true })
  industry?: string;

  @Column({ nullable: true })
  website?: string;

  @Column({ nullable: true })
  address?: string;

  @Column({ nullable: true })
  primaryContactName?: string;

  @Column({ nullable: true })
  primaryContactEmail?: string;

  @Column({ nullable: true })
  primaryContactPhone?: string;

  @Column({ type: 'text', nullable: true })
  notes?: string;

  @Column({ default: false })
  isArchived: boolean;

  /** Set when `isArchived` transitions to true, cleared on reactivation —
   * lets Agency Reporting count "clients lost" within a date range, which
   * `isArchived` alone (a plain snapshot flag) can't answer. */
  @Column({ type: 'timestamptz', nullable: true })
  archivedAt: Date | null;

  /** Current health snapshot — the source of truth for badges/dashboards.
   * `ClientHealthHistory` holds the trail of how it got here; this column is
   * never derived/recomputed from that trail, only set directly by
   * `updateClientHealth`. */
  @Column({
    type: 'enum',
    enum: ClientHealthStatus,
    enumName: 'client_health_status_enum',
    default: ClientHealthStatus.HEALTHY,
  })
  healthStatus: ClientHealthStatus;

  @Column({ type: 'text', array: true, default: () => "'{}'" })
  healthFactors: string[];

  @Column({ type: 'text', nullable: true })
  healthNotes?: string;
}
