import { NotFoundException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { Holiday } from '../domain/entities/holiday.entity';
import type { HolidayRepository } from '../domain/repositories/holiday-repository.interface';
import { HolidaysService } from './holidays.service';
import { UpdateHolidayDto } from './dto/update-holiday.dto';

function buildHoliday(overrides: Partial<Holiday> = {}): Holiday {
  return {
    id: 'holiday-1',
    name: 'New Year',
    date: '2026-01-01',
    ...overrides,
  } as Holiday;
}

describe('HolidaysService', () => {
  let service: HolidaysService;
  let holidayRepository: jest.Mocked<HolidayRepository>;

  beforeEach(() => {
    holidayRepository = {
      findAll: jest.fn(),
      findByRange: jest.fn(),
      findById: jest.fn(),
      save: jest.fn(),
      remove: jest.fn(),
    };

    service = new HolidaysService(holidayRepository);
  });

  describe('getAll', () => {
    it('passes the year through to the repository', async () => {
      holidayRepository.findAll.mockResolvedValue([buildHoliday()]);

      await service.getAll(2026);

      expect(holidayRepository.findAll).toHaveBeenCalledWith(2026);
    });

    it('passes undefined through when no year is given', async () => {
      holidayRepository.findAll.mockResolvedValue([]);

      await service.getAll();

      expect(holidayRepository.findAll).toHaveBeenCalledWith(undefined);
    });
  });

  describe('getDatesInRange', () => {
    it('maps holidays to their ISO date strings', async () => {
      holidayRepository.findByRange.mockResolvedValue([
        buildHoliday({ id: 'holiday-1', date: '2026-01-01' }),
        buildHoliday({ id: 'holiday-2', date: '2026-01-26' }),
      ]);

      const result = await service.getDatesInRange('2026-01-01', '2026-01-31');

      expect(holidayRepository.findByRange).toHaveBeenCalledWith(
        '2026-01-01',
        '2026-01-31',
      );
      expect(result).toEqual(['2026-01-01', '2026-01-26']);
    });
  });

  describe('create', () => {
    it('saves a new holiday with the given fields', async () => {
      holidayRepository.save.mockImplementation((holiday) =>
        Promise.resolve(holiday),
      );

      const result = await service.create({
        name: 'New Year',
        date: '2026-01-01',
      });

      expect(result.name).toBe('New Year');
      expect(result.date).toBe('2026-01-01');
    });
  });

  describe('update', () => {
    it('applies only the given fields onto the existing holiday', async () => {
      const existing = buildHoliday();
      holidayRepository.findById.mockResolvedValue(existing);
      holidayRepository.save.mockImplementation((holiday) =>
        Promise.resolve(holiday),
      );

      const result = await service.update('holiday-1', {
        name: "New Year's Day",
      });

      expect(result.name).toBe("New Year's Day");
      // Fields not present in the DTO are left untouched.
      expect(result.date).toBe('2026-01-01');
    });

    it('updating the name alone does not wipe the date — regression test for the real request shape', async () => {
      // A plain object literal like `{ name: '...' }` has no `date` key at
      // all, so it can't reproduce this bug. The real HTTP pipeline runs the
      // body through class-transformer first, and every declared-but-unset
      // field on the resulting instance is an explicit `undefined` own
      // property (`useDefineForClassFields`) — that's what would previously
      // make `Object.assign(holiday, dto)` overwrite `date` with `undefined`.
      const dto = plainToInstance(UpdateHolidayDto, { name: 'Renamed' });
      expect(Object.keys(dto)).toContain('date');

      const existing = buildHoliday();
      holidayRepository.findById.mockResolvedValue(existing);
      holidayRepository.save.mockImplementation((holiday) =>
        Promise.resolve(holiday),
      );

      const result = await service.update('holiday-1', dto);

      expect(result.name).toBe('Renamed');
      expect(result.date).toBe('2026-01-01');
    });

    it('throws NotFoundException when the holiday does not exist', async () => {
      holidayRepository.findById.mockResolvedValue(null);

      await expect(
        service.update('missing-holiday', { name: 'New Name' }),
      ).rejects.toThrow(NotFoundException);
      expect(holidayRepository.save).not.toHaveBeenCalled();
    });
  });

  describe('remove', () => {
    it('removes the holiday when it exists', async () => {
      const existing = buildHoliday();
      holidayRepository.findById.mockResolvedValue(existing);
      holidayRepository.remove.mockResolvedValue(undefined);

      await service.remove('holiday-1');

      expect(holidayRepository.remove).toHaveBeenCalledWith(existing);
    });

    it('throws NotFoundException when the holiday does not exist', async () => {
      holidayRepository.findById.mockResolvedValue(null);

      await expect(service.remove('missing-holiday')).rejects.toThrow(
        NotFoundException,
      );
      expect(holidayRepository.remove).not.toHaveBeenCalled();
    });
  });
});
