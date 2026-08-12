import { Column, Entity } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { AssetStatus } from '../enums/asset-status.enum';

@Entity('assets')
export class Asset extends BaseEntity {
  @Column()
  name: string;

  @Column({ nullable: true })
  category?: string;

  @Column({ nullable: true })
  serialNumber?: string;

  @Column({ type: 'enum', enum: AssetStatus, default: AssetStatus.AVAILABLE })
  status: AssetStatus;

  /** Toggled between a value and null by assign/unassign — unlike most
   * nullable columns here (simply "not yet filled in"), so it's typed
   * `| null` rather than optional (`?`). */
  @Column({ type: 'uuid', nullable: true })
  assignedEmployeeId: string | null;

  @Column({ type: 'timestamptz', nullable: true })
  assignedAt: Date | null;

  @Column({ type: 'text', nullable: true })
  notes?: string;
}
