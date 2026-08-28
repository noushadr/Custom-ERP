import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { ChecklistTemplateItem } from '../../domain/entities/checklist-template-item.entity';
import { ChecklistType } from '../../domain/enums/checklist-type.enum';
import { ChecklistTemplateRepository } from '../../domain/repositories/checklist-template-repository.interface';

@Injectable()
export class TypeOrmChecklistTemplateRepository
  implements ChecklistTemplateRepository
{
  constructor(
    @InjectRepository(ChecklistTemplateItem)
    private readonly repository: Repository<ChecklistTemplateItem>,
  ) {}

  findAll(
    type: ChecklistType,
    includeArchived = false,
  ): Promise<ChecklistTemplateItem[]> {
    return this.repository.find({
      where: includeArchived ? { type } : { type, isArchived: false },
      order: { sortOrder: 'ASC' },
    });
  }

  findById(id: string): Promise<ChecklistTemplateItem | null> {
    return this.repository.findOne({ where: { id } });
  }

  findByIds(ids: string[]): Promise<ChecklistTemplateItem[]> {
    if (ids.length === 0) return Promise.resolve([]);
    return this.repository.find({ where: { id: In(ids) } });
  }

  save(item: ChecklistTemplateItem): Promise<ChecklistTemplateItem> {
    return this.repository.save(item);
  }

  saveMany(
    items: ChecklistTemplateItem[],
  ): Promise<ChecklistTemplateItem[]> {
    return this.repository.save(items);
  }

  async remove(item: ChecklistTemplateItem): Promise<void> {
    await this.repository.remove(item);
  }
}
