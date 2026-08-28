import { Column, Entity } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { WorkMode } from '../../../employee/domain/enums/work-mode.enum';
import { ChecklistType } from '../enums/checklist-type.enum';

/** A configurable, company-wide onboarding/offboarding step — HR/Admin
 * manages this list; instances snapshot from it per employee. */
@Entity('checklist_template_items')
export class ChecklistTemplateItem extends BaseEntity {
  @Column({ type: 'enum', enum: ChecklistType })
  type: ChecklistType;

  @Column()
  title: string;

  @Column({ nullable: true })
  description?: string;

  @Column({ type: 'int' })
  sortOrder: number;

  /** Null means every employee regardless of work mode; set to a specific
   * mode (e.g. ON_SITE for "office rules and regulations") to restrict it. */
  @Column({ type: 'enum', enum: WorkMode, nullable: true })
  appliesToWorkMode?: WorkMode;

  @Column({ default: false })
  isArchived: boolean;
}
