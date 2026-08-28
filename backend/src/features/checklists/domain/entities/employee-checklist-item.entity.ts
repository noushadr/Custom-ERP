import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../../core/database/base.entity';
import { Employee } from '../../../employee/domain/entities/employee.entity';
import { ChecklistType } from '../enums/checklist-type.enum';
import { ChecklistTemplateItem } from './checklist-template-item.entity';

/** One step of a specific employee's onboarding/offboarding checklist.
 * `title`/`sortOrder` are snapshotted from the template at creation time, so
 * later template edits or archiving never change an already-instantiated
 * checklist. */
@Entity('employee_checklist_items')
export class EmployeeChecklistItem extends BaseEntity {
  @Column()
  employeeId: string;

  @ManyToOne(() => Employee, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'employeeId' })
  employee: Employee;

  @Column({ nullable: true })
  templateItemId?: string;

  @ManyToOne(() => ChecklistTemplateItem)
  @JoinColumn({ name: 'templateItemId' })
  templateItem?: ChecklistTemplateItem;

  @Column({ type: 'enum', enum: ChecklistType })
  type: ChecklistType;

  @Column()
  title: string;

  @Column({ type: 'int' })
  sortOrder: number;

  @Column({ default: false })
  isCompleted: boolean;

  @Column({ type: 'timestamptz', nullable: true })
  completedAt?: Date;

  @Column({ nullable: true })
  completedByUserId?: string;

  @Column({ nullable: true })
  completedByName?: string;

  @Column({ nullable: true })
  note?: string;
}
