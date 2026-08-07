import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EducationRecord } from '../../domain/entities/education-record.entity';
import { EducationRecordRepository } from '../../domain/repositories/education-record-repository.interface';

@Injectable()
export class TypeOrmEducationRecordRepository implements EducationRecordRepository {
  constructor(
    @InjectRepository(EducationRecord)
    private readonly repository: Repository<EducationRecord>,
  ) {}

  findByEmployeeId(employeeId: string): Promise<EducationRecord[]> {
    return this.repository.find({
      where: { employeeId },
      order: { yearCompleted: 'ASC', createdAt: 'ASC' },
    });
  }

  findById(id: string): Promise<EducationRecord | null> {
    return this.repository.findOne({ where: { id } });
  }

  save(record: EducationRecord): Promise<EducationRecord> {
    return this.repository.save(record);
  }

  async remove(record: EducationRecord): Promise<void> {
    await this.repository.remove(record);
  }
}
