import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Client } from './client.entity';
import { ClientHealthStatus } from '../enums/client-health-status.enum';

/** One immutable row per health update — identical shape/convention to
 * TaskAuditLog, so a client's health trail is a plain readable timeline of
 * who changed the status, when, to what, and why (factors + notes). Never
 * written at client creation — only on an explicit `updateClientHealth`
 * call, matching the "manual status+notes updates" requirement. */
@Entity('client_health_history')
export class ClientHealthHistory extends BaseEntity {
  @Column()
  clientId: string;

  @ManyToOne(() => Client, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'clientId' })
  client: Client;

  @Column({
    type: 'enum',
    enum: ClientHealthStatus,
    enumName: 'client_health_status_enum',
  })
  previousStatus: ClientHealthStatus;

  @Column({
    type: 'enum',
    enum: ClientHealthStatus,
    enumName: 'client_health_status_enum',
  })
  newStatus: ClientHealthStatus;

  @Column({ type: 'text', array: true, default: () => "'{}'" })
  factors: string[];

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @Column()
  actorUserId: string;

  /** Snapshot of the actor's display name at the time of the change. */
  @Column()
  actorName: string;
}
