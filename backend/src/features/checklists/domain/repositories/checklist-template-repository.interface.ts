import { ChecklistTemplateItem } from '../entities/checklist-template-item.entity';
import { ChecklistType } from '../enums/checklist-type.enum';

export const CHECKLIST_TEMPLATE_REPOSITORY = Symbol(
  'CHECKLIST_TEMPLATE_REPOSITORY',
);

export interface ChecklistTemplateRepository {
  findAll(
    type: ChecklistType,
    includeArchived?: boolean,
  ): Promise<ChecklistTemplateItem[]>;
  findById(id: string): Promise<ChecklistTemplateItem | null>;
  findByIds(ids: string[]): Promise<ChecklistTemplateItem[]>;
  save(item: ChecklistTemplateItem): Promise<ChecklistTemplateItem>;
  saveMany(
    items: ChecklistTemplateItem[],
  ): Promise<ChecklistTemplateItem[]>;
  remove(item: ChecklistTemplateItem): Promise<void>;
}
