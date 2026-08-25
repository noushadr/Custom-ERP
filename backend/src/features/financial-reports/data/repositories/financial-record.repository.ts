import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { FinancialRecord } from '../../domain/entities/financial-record.entity';
import { FinancialRecordRepository } from '../../domain/repositories/financial-record-repository.interface';

@Injectable()
export class TypeOrmFinancialRecordRepository
  implements FinancialRecordRepository
{
  constructor(
    @InjectRepository(FinancialRecord)
    private readonly repository: Repository<FinancialRecord>,
  ) {}

  findAll(): Promise<FinancialRecord[]> {
    return this.repository.find({ order: { year: 'ASC', month: 'ASC' } });
  }

  findById(id: string): Promise<FinancialRecord | null> {
    return this.repository.findOne({ where: { id } });
  }

  findByYearMonth(
    year: number,
    month: number,
  ): Promise<FinancialRecord | null> {
    return this.repository.findOne({ where: { year, month } });
  }

  save(record: FinancialRecord): Promise<FinancialRecord> {
    return this.repository.save(record);
  }
}
