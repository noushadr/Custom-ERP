import { Column, Entity, Index } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { AutomationRunStatus } from '../enums/automation-run-status.enum';
import { AutomationRunTrigger } from '../enums/automation-run-trigger.enum';
import { AutomationType } from '../enums/automation-type.enum';

/** One immutable row per run of an automation (daily cron or a manual "Run
 * Now") — same "one row per state-changing action" convention as
 * ClientHealthHistory/TaskAuditLog, but system-triggered rather than
 * user-actioned, so `triggeredBy` replaces an actor. `createdAt` (from
 * BaseEntity) doubles as "ran at". */
@Index(['type', 'createdAt'])
@Entity('automation_execution_history')
export class AutomationExecutionHistory extends BaseEntity {
  @Column({ type: 'enum', enum: AutomationType, enumName: 'automation_type_enum' })
  type: AutomationType;

  @Column({ type: 'enum', enum: AutomationRunTrigger })
  triggeredBy: AutomationRunTrigger;

  @Column({ type: 'enum', enum: AutomationRunStatus })
  status: AutomationRunStatus;

  @Column({ type: 'int', default: 0 })
  itemsProcessed: number;

  @Column({ type: 'int', default: 0 })
  notificationsCreated: number;

  @Column({ type: 'text', nullable: true })
  errorMessage: string | null;
}
