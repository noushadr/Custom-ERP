import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { definedFieldsOnly } from '../../../core/utils/defined-fields-only.util';
import { Holiday } from '../domain/entities/holiday.entity';
import {
  HOLIDAY_REPOSITORY,
  type HolidayRepository,
} from '../domain/repositories/holiday-repository.interface';
import { CreateHolidayDto } from './dto/create-holiday.dto';
import { UpdateHolidayDto } from './dto/update-holiday.dto';

@Injectable()
export class HolidaysService {
  constructor(
    @Inject(HOLIDAY_REPOSITORY)
    private readonly holidayRepository: HolidayRepository,
  ) {}

  getAll(year?: number): Promise<Holiday[]> {
    return this.holidayRepository.findAll(year);
  }

  async getDatesInRange(startDate: string, endDate: string): Promise<string[]> {
    const holidays = await this.holidayRepository.findByRange(
      startDate,
      endDate,
    );
    return holidays.map((h) => h.date);
  }

  create(dto: CreateHolidayDto): Promise<Holiday> {
    const holiday = new Holiday();
    holiday.name = dto.name;
    holiday.date = dto.date;
    return this.holidayRepository.save(holiday);
  }

  async update(id: string, dto: UpdateHolidayDto): Promise<Holiday> {
    const holiday = await this.holidayRepository.findById(id);
    if (!holiday) throw new NotFoundException('Holiday not found');

    Object.assign(holiday, definedFieldsOnly(dto));
    return this.holidayRepository.save(holiday);
  }

  async remove(id: string): Promise<void> {
    const holiday = await this.holidayRepository.findById(id);
    if (!holiday) throw new NotFoundException('Holiday not found');
    await this.holidayRepository.remove(holiday);
  }
}
