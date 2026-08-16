import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Between, Repository } from 'typeorm';
import { Holiday } from '../../domain/entities/holiday.entity';
import { HolidayRepository } from '../../domain/repositories/holiday-repository.interface';

@Injectable()
export class TypeOrmHolidayRepository implements HolidayRepository {
  constructor(
    @InjectRepository(Holiday)
    private readonly repository: Repository<Holiday>,
  ) {}

  findAll(year?: number): Promise<Holiday[]> {
    return this.repository.find({
      where: year
        ? { date: Between(`${year}-01-01`, `${year}-12-31`) }
        : {},
      order: { date: 'ASC' },
    });
  }

  findByRange(startDate: string, endDate: string): Promise<Holiday[]> {
    return this.repository.find({
      where: { date: Between(startDate, endDate) },
      order: { date: 'ASC' },
    });
  }

  findById(id: string): Promise<Holiday | null> {
    return this.repository.findOne({ where: { id } });
  }

  save(holiday: Holiday): Promise<Holiday> {
    return this.repository.save(holiday);
  }

  async remove(holiday: Holiday): Promise<void> {
    await this.repository.remove(holiday);
  }
}
