import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AutomationExecutionHistory } from '../../domain/entities/automation-execution-history.entity';
import { AutomationType } from '../../domain/enums/automation-type.enum';
import { AutomationExecutionHistoryRepository } from '../../domain/repositories/automation-execution-history-repository.interface';

@Injectable()
export class TypeOrmAutomationExecutionHistoryRepository
  implements AutomationExecutionHistoryRepository
{
  constructor(
    @InjectRepository(AutomationExecutionHistory)
    private readonly repository: Repository<AutomationExecutionHistory>,
  ) {}

  findAll(type?: AutomationType): Promise<AutomationExecutionHistory[]> {
    return this.repository.find({
      where: type ? { type } : {},
      order: { createdAt: 'DESC' },
    });
  }

  save(
    entry: AutomationExecutionHistory,
  ): Promise<AutomationExecutionHistory> {
    return this.repository.save(entry);
  }
}
