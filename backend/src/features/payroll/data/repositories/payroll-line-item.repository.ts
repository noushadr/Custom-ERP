import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PayrollLineItem } from '../../domain/entities/payroll-line-item.entity';
import { PayrollLineItemRepository } from '../../domain/repositories/payroll-line-item-repository.interface';

@Injectable()
export class TypeOrmPayrollLineItemRepository
  implements PayrollLineItemRepository
{
  constructor(
    @InjectRepository(PayrollLineItem)
    private readonly repository: Repository<PayrollLineItem>,
  ) {}

  findByRunId(runId: string): Promise<PayrollLineItem[]> {
    return this.repository.find({
      where: { runId },
      order: { createdAt: 'ASC' },
    });
  }

  findById(id: string): Promise<PayrollLineItem | null> {
    return this.repository.findOne({ where: { id } });
  }

  save(item: PayrollLineItem): Promise<PayrollLineItem> {
    return this.repository.save(item);
  }

  saveMany(items: PayrollLineItem[]): Promise<PayrollLineItem[]> {
    return this.repository.save(items);
  }
}
