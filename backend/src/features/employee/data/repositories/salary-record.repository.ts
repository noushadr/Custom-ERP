import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SalaryRecord } from '../../domain/entities/salary-record.entity';
import { SalaryRecordRepository } from '../../domain/repositories/salary-record-repository.interface';

@Injectable()
export class TypeOrmSalaryRecordRepository implements SalaryRecordRepository {
  constructor(
    @InjectRepository(SalaryRecord)
    private readonly repository: Repository<SalaryRecord>,
  ) {}

  findByEmployeeId(employeeId: string): Promise<SalaryRecord[]> {
    return this.repository.find({
      where: { employeeId },
      order: { effectiveDate: 'ASC', createdAt: 'ASC' },
    });
  }

  findById(id: string): Promise<SalaryRecord | null> {
    return this.repository.findOne({ where: { id } });
  }

  save(record: SalaryRecord): Promise<SalaryRecord> {
    return this.repository.save(record);
  }

  async remove(record: SalaryRecord): Promise<void> {
    await this.repository.remove(record);
  }
}
