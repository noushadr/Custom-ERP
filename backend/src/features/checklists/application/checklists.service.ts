import { ConflictException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import { definedFieldsOnly } from '../../../core/utils/defined-fields-only.util';
import { WorkMode } from '../../employee/domain/enums/work-mode.enum';
import { ChecklistTemplateItem } from '../domain/entities/checklist-template-item.entity';
import { EmployeeChecklistItem } from '../domain/entities/employee-checklist-item.entity';
import { ChecklistType } from '../domain/enums/checklist-type.enum';
import {
  CHECKLIST_TEMPLATE_REPOSITORY,
  type ChecklistTemplateRepository,
} from '../domain/repositories/checklist-template-repository.interface';
import {
  EMPLOYEE_CHECKLIST_REPOSITORY,
  type EmployeeChecklistRepository,
} from '../domain/repositories/employee-checklist-repository.interface';
import { CreateChecklistTemplateItemDto } from './dto/create-checklist-template-item.dto';
import { ReorderChecklistTemplateItemsDto } from './dto/reorder-checklist-template-items.dto';
import { SetChecklistItemCompletedDto } from './dto/set-checklist-item-completed.dto';
import { UpdateChecklistTemplateItemDto } from './dto/update-checklist-template-item.dto';

const FOREIGN_KEY_VIOLATION = '23503';

@Injectable()
export class ChecklistsService {
  constructor(
    @Inject(CHECKLIST_TEMPLATE_REPOSITORY)
    private readonly templateRepository: ChecklistTemplateRepository,
    @Inject(EMPLOYEE_CHECKLIST_REPOSITORY)
    private readonly instanceRepository: EmployeeChecklistRepository,
  ) {}

  // ---- Template management (configurable by employees.manage holders) ----

  getTemplateItems(
    type: ChecklistType,
    includeArchived = false,
  ): Promise<ChecklistTemplateItem[]> {
    return this.templateRepository.findAll(type, includeArchived);
  }

  async createTemplateItem(
    dto: CreateChecklistTemplateItemDto,
  ): Promise<ChecklistTemplateItem> {
    const existing = await this.templateRepository.findAll(dto.type, true);

    const item = new ChecklistTemplateItem();
    item.type = dto.type;
    item.title = dto.title;
    item.description = dto.description;
    item.appliesToWorkMode = dto.appliesToWorkMode ?? undefined;
    item.sortOrder = existing.length;
    item.isArchived = false;
    return this.templateRepository.save(item);
  }

  async updateTemplateItem(
    id: string,
    dto: UpdateChecklistTemplateItemDto,
  ): Promise<ChecklistTemplateItem> {
    const item = await this.templateRepository.findById(id);
    if (!item) throw new NotFoundException('Checklist template item not found');

    Object.assign(item, definedFieldsOnly(dto));
    return this.templateRepository.save(item);
  }

  /** Sets sortOrder = index for each listed id — items of this type not
   * included are left untouched (defensively, though the frontend always
   * sends the complete list). */
  async reorderTemplateItems(
    dto: ReorderChecklistTemplateItemsDto,
  ): Promise<ChecklistTemplateItem[]> {
    const items = await this.templateRepository.findByIds(dto.orderedIds);
    const byId = new Map(items.map((item) => [item.id, item]));

    const reordered: ChecklistTemplateItem[] = [];
    dto.orderedIds.forEach((id, index) => {
      const item = byId.get(id);
      if (!item || item.type !== dto.type) return;
      item.sortOrder = index;
      reordered.push(item);
    });
    return this.templateRepository.saveMany(reordered);
  }

  async deleteTemplateItem(id: string): Promise<void> {
    const item = await this.templateRepository.findById(id);
    if (!item) throw new NotFoundException('Checklist template item not found');

    try {
      await this.templateRepository.remove(item);
    } catch (error) {
      if (this.isForeignKeyViolation(error)) {
        throw new ConflictException(
          'Cannot delete a checklist item that already has employee ' +
            'checklists created against it. Archive it instead.',
        );
      }
      throw error;
    }
  }

  // ---- Per-employee instances ----

  /** Snapshots every current, applicable template item of [type] onto
   * [employeeId] — applicable meaning `appliesToWorkMode` is unset or matches
   * [workMode]. Idempotent: a no-op if this employee already has any items of
   * this type, so it's safe to call on every relevant employment-status
   * transition without duplicating an already-started checklist. */
  async createInstance(
    employeeId: string,
    type: ChecklistType,
    workMode: WorkMode,
  ): Promise<EmployeeChecklistItem[]> {
    const existing = await this.instanceRepository.findByEmployeeAndType(
      employeeId,
      type,
    );
    if (existing.length > 0) return existing;

    const templateItems = await this.templateRepository.findAll(type, false);
    const applicable = templateItems.filter(
      (item) =>
        item.appliesToWorkMode == null || item.appliesToWorkMode === workMode,
    );
    if (applicable.length === 0) return [];

    const instances = applicable.map((templateItem) => {
      const instance = new EmployeeChecklistItem();
      instance.employeeId = employeeId;
      instance.templateItemId = templateItem.id;
      instance.type = type;
      instance.title = templateItem.title;
      instance.sortOrder = templateItem.sortOrder;
      instance.isCompleted = false;
      return instance;
    });
    return this.instanceRepository.saveMany(instances);
  }

  getEmployeeChecklist(
    employeeId: string,
    type: ChecklistType,
  ): Promise<EmployeeChecklistItem[]> {
    return this.instanceRepository.findByEmployeeAndType(employeeId, type);
  }

  async setItemCompleted(
    itemId: string,
    dto: SetChecklistItemCompletedDto,
    actorUserId: string,
    actorName: string,
  ): Promise<EmployeeChecklistItem> {
    const item = await this.instanceRepository.findById(itemId);
    if (!item) throw new NotFoundException('Checklist item not found');

    item.isCompleted = dto.isCompleted;
    item.note = dto.note;
    if (dto.isCompleted) {
      item.completedAt = new Date();
      item.completedByUserId = actorUserId;
      item.completedByName = actorName;
    } else {
      item.completedAt = undefined;
      item.completedByUserId = undefined;
      item.completedByName = undefined;
    }
    return this.instanceRepository.save(item);
  }

  private isForeignKeyViolation(error: unknown): boolean {
    const code =
      (error as { code?: string })?.code ??
      (error as { driverError?: { code?: string } })?.driverError?.code;
    return code === FOREIGN_KEY_VIOLATION;
  }
}
