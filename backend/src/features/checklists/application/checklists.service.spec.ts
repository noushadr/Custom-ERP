import { ConflictException, NotFoundException } from '@nestjs/common';
import { WorkMode } from '../../employee/domain/enums/work-mode.enum';
import { ChecklistTemplateItem } from '../domain/entities/checklist-template-item.entity';
import { EmployeeChecklistItem } from '../domain/entities/employee-checklist-item.entity';
import { ChecklistType } from '../domain/enums/checklist-type.enum';
import type { ChecklistTemplateRepository } from '../domain/repositories/checklist-template-repository.interface';
import type { EmployeeChecklistRepository } from '../domain/repositories/employee-checklist-repository.interface';
import { ChecklistsService } from './checklists.service';

function buildTemplateItem(
  overrides: Partial<ChecklistTemplateItem> = {},
): ChecklistTemplateItem {
  return {
    id: 'template-1',
    type: ChecklistType.ONBOARDING,
    title: 'Acceptance of offer letter via email',
    sortOrder: 0,
    isArchived: false,
    ...overrides,
  } as ChecklistTemplateItem;
}

function buildInstanceItem(
  overrides: Partial<EmployeeChecklistItem> = {},
): EmployeeChecklistItem {
  return {
    id: 'instance-1',
    employeeId: 'employee-1',
    templateItemId: 'template-1',
    type: ChecklistType.ONBOARDING,
    title: 'Acceptance of offer letter via email',
    sortOrder: 0,
    isCompleted: false,
    ...overrides,
  } as EmployeeChecklistItem;
}

describe('ChecklistsService', () => {
  let service: ChecklistsService;
  let templateRepository: jest.Mocked<ChecklistTemplateRepository>;
  let instanceRepository: jest.Mocked<EmployeeChecklistRepository>;

  beforeEach(() => {
    templateRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      findByIds: jest.fn(),
      save: jest.fn((item) => Promise.resolve(item)),
      saveMany: jest.fn((items) => Promise.resolve(items)),
      remove: jest.fn(),
    };
    instanceRepository = {
      findByEmployeeAndType: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      save: jest.fn((item) => Promise.resolve(item)),
      saveMany: jest.fn((items) => Promise.resolve(items)),
    };

    service = new ChecklistsService(templateRepository, instanceRepository);
  });

  describe('createTemplateItem', () => {
    it('appends the new item to the end of the existing list for its type', async () => {
      templateRepository.findAll.mockResolvedValue([
        buildTemplateItem({ id: 'a' }),
        buildTemplateItem({ id: 'b' }),
      ]);

      const result = await service.createTemplateItem({
        type: ChecklistType.ONBOARDING,
        title: 'New step',
      });

      expect(result.sortOrder).toBe(2);
      expect(result.title).toBe('New step');
      expect(result.isArchived).toBe(false);
    });
  });

  describe('updateTemplateItem', () => {
    it('throws NotFoundException when missing', async () => {
      templateRepository.findById.mockResolvedValue(null);

      await expect(
        service.updateTemplateItem('missing', { title: 'New title' }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('only touches fields explicitly provided', async () => {
      const item = buildTemplateItem({ description: 'Old description' });
      templateRepository.findById.mockResolvedValue(item);

      const result = await service.updateTemplateItem(item.id, {
        title: 'Updated title',
      });

      expect(result.title).toBe('Updated title');
      expect(result.description).toBe('Old description');
    });

    it('clears appliesToWorkMode back to "everyone" when sent null', async () => {
      const item = buildTemplateItem({ appliesToWorkMode: WorkMode.ON_SITE });
      templateRepository.findById.mockResolvedValue(item);

      const result = await service.updateTemplateItem(item.id, {
        appliesToWorkMode: null,
      });

      expect(result.appliesToWorkMode).toBeNull();
    });
  });

  describe('reorderTemplateItems', () => {
    it('sets sortOrder to each id\'s position in the given order', async () => {
      const a = buildTemplateItem({ id: 'a', sortOrder: 0 });
      const b = buildTemplateItem({ id: 'b', sortOrder: 1 });
      const c = buildTemplateItem({ id: 'c', sortOrder: 2 });
      templateRepository.findByIds.mockResolvedValue([a, b, c]);

      const result = await service.reorderTemplateItems({
        type: ChecklistType.ONBOARDING,
        orderedIds: ['c', 'a', 'b'],
      });

      expect(result.find((i) => i.id === 'c')!.sortOrder).toBe(0);
      expect(result.find((i) => i.id === 'a')!.sortOrder).toBe(1);
      expect(result.find((i) => i.id === 'b')!.sortOrder).toBe(2);
    });

    it('ignores an id belonging to a different checklist type', async () => {
      const a = buildTemplateItem({ id: 'a', type: ChecklistType.ONBOARDING });
      const offboarding = buildTemplateItem({
        id: 'x',
        type: ChecklistType.OFFBOARDING,
      });
      templateRepository.findByIds.mockResolvedValue([a, offboarding]);

      const result = await service.reorderTemplateItems({
        type: ChecklistType.ONBOARDING,
        orderedIds: ['x', 'a'],
      });

      expect(result.map((i) => i.id)).toEqual(['a']);
    });
  });

  describe('deleteTemplateItem', () => {
    it('throws NotFoundException when missing', async () => {
      templateRepository.findById.mockResolvedValue(null);

      await expect(service.deleteTemplateItem('missing')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('removes an unreferenced item', async () => {
      const item = buildTemplateItem();
      templateRepository.findById.mockResolvedValue(item);

      await service.deleteTemplateItem(item.id);

      expect(templateRepository.remove).toHaveBeenCalledWith(item);
    });

    it('translates a foreign-key violation into a friendly ConflictException', async () => {
      const item = buildTemplateItem();
      templateRepository.findById.mockResolvedValue(item);
      templateRepository.remove.mockRejectedValue({ code: '23503' });

      await expect(service.deleteTemplateItem(item.id)).rejects.toBeInstanceOf(
        ConflictException,
      );
    });
  });

  describe('createInstance', () => {
    it('snapshots every applicable template item for the given work mode', async () => {
      templateRepository.findAll.mockResolvedValue([
        buildTemplateItem({ id: 't1', title: 'Everyone item', sortOrder: 0 }),
        buildTemplateItem({
          id: 't2',
          title: 'On-site only item',
          sortOrder: 1,
          appliesToWorkMode: WorkMode.ON_SITE,
        }),
      ]);

      const result = await service.createInstance(
        'employee-1',
        ChecklistType.ONBOARDING,
        WorkMode.REMOTE,
      );

      expect(result.map((i) => i.title)).toEqual(['Everyone item']);
    });

    it('includes a work-mode-restricted item for a matching employee', async () => {
      templateRepository.findAll.mockResolvedValue([
        buildTemplateItem({ id: 't1', title: 'Everyone item', sortOrder: 0 }),
        buildTemplateItem({
          id: 't2',
          title: 'On-site only item',
          sortOrder: 1,
          appliesToWorkMode: WorkMode.ON_SITE,
        }),
      ]);

      const result = await service.createInstance(
        'employee-1',
        ChecklistType.ONBOARDING,
        WorkMode.ON_SITE,
      );

      expect(result.map((i) => i.title)).toEqual([
        'Everyone item',
        'On-site only item',
      ]);
    });

    it('is idempotent — a second call returns the existing instance without duplicating it', async () => {
      const existing = [buildInstanceItem()];
      instanceRepository.findByEmployeeAndType.mockResolvedValue(existing);

      const result = await service.createInstance(
        'employee-1',
        ChecklistType.ONBOARDING,
        WorkMode.ON_SITE,
      );

      expect(result).toBe(existing);
      expect(templateRepository.findAll).not.toHaveBeenCalled();
      expect(instanceRepository.saveMany).not.toHaveBeenCalled();
    });
  });

  describe('setItemCompleted', () => {
    it('throws NotFoundException when missing', async () => {
      instanceRepository.findById.mockResolvedValue(null);

      await expect(
        service.setItemCompleted(
          'missing',
          { isCompleted: true },
          'actor-1',
          'Jane Doe',
        ),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('records the actor, timestamp, and note when marking an item complete', async () => {
      const item = buildInstanceItem();
      instanceRepository.findById.mockResolvedValue(item);

      const result = await service.setItemCompleted(
        item.id,
        { isCompleted: true, note: 'Signed on Aug 20' },
        'actor-1',
        'Jane Doe',
      );

      expect(result.isCompleted).toBe(true);
      expect(result.completedByUserId).toBe('actor-1');
      expect(result.completedByName).toBe('Jane Doe');
      expect(result.note).toBe('Signed on Aug 20');
      expect(result.completedAt).toBeInstanceOf(Date);
    });

    it('clears the completion details when toggled back to incomplete', async () => {
      const item = buildInstanceItem({
        isCompleted: true,
        completedAt: new Date('2026-01-01'),
        completedByUserId: 'actor-1',
        completedByName: 'Jane Doe',
      });
      instanceRepository.findById.mockResolvedValue(item);

      const result = await service.setItemCompleted(
        item.id,
        { isCompleted: false },
        'actor-1',
        'Jane Doe',
      );

      expect(result.isCompleted).toBe(false);
      expect(result.completedAt).toBeUndefined();
      expect(result.completedByUserId).toBeUndefined();
      expect(result.completedByName).toBeUndefined();
    });
  });
});
