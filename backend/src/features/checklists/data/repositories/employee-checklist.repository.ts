import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EmployeeChecklistItem } from '../../domain/entities/employee-checklist-item.entity';
import { ChecklistType } from '../../domain/enums/checklist-type.enum';
import { EmployeeChecklistRepository } from '../../domain/repositories/employee-checklist-repository.interface';

@Injectable()
export class TypeOrmEmployeeChecklistRepository
  implements EmployeeChecklistRepository
{
  constructor(
    @InjectRepository(EmployeeChecklistItem)
    private readonly repository: Repository<EmployeeChecklistItem>,
  ) {}

  findByEmployeeAndType(
    employeeId: string,
    type: ChecklistType,
  ): Promise<EmployeeChecklistItem[]> {
    return this.repository.find({
      where: { employeeId, type },
      order: { sortOrder: 'ASC' },
    });
  }

  findById(id: string): Promise<EmployeeChecklistItem | null> {
    return this.repository.findOne({ where: { id } });
  }

  save(item: EmployeeChecklistItem): Promise<EmployeeChecklistItem> {
    return this.repository.save(item);
  }

  saveMany(
    items: EmployeeChecklistItem[],
  ): Promise<EmployeeChecklistItem[]> {
    return this.repository.save(items);
  }
}
