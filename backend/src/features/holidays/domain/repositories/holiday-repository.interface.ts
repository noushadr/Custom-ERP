import { Holiday } from '../entities/holiday.entity';

export const HOLIDAY_REPOSITORY = Symbol('HOLIDAY_REPOSITORY');

export interface HolidayRepository {
  findAll(year?: number): Promise<Holiday[]>;
  findByRange(startDate: string, endDate: string): Promise<Holiday[]>;
  findById(id: string): Promise<Holiday | null>;
  save(holiday: Holiday): Promise<Holiday>;
  remove(holiday: Holiday): Promise<void>;
}
