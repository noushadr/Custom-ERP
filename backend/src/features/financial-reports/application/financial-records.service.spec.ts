import { ConflictException, NotFoundException } from '@nestjs/common';
import { FinancialRecord } from '../domain/entities/financial-record.entity';
import type { FinancialRecordRepository } from '../domain/repositories/financial-record-repository.interface';
import { FinancialRecordsService } from './financial-records.service';

function buildRecord(overrides: Partial<FinancialRecord> = {}): FinancialRecord {
  return {
    id: 'record-1',
    year: 2026,
    month: 1,
    revenueRs: '1000000.00',
    revenueUsd: '3571.43',
    expenseRs: '600000.00',
    expenseUsd: '2142.86',
    fxRate: '280.00',
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    updatedAt: new Date('2026-01-01T00:00:00.000Z'),
    ...overrides,
  } as FinancialRecord;
}

describe('FinancialRecordsService', () => {
  let service: FinancialRecordsService;
  let financialRecordRepository: jest.Mocked<FinancialRecordRepository>;

  beforeEach(() => {
    const stampTimestamps = (item: { createdAt?: Date; updatedAt?: Date }) => ({
      ...item,
      createdAt: item.createdAt ?? new Date('2026-01-01T00:00:00.000Z'),
      updatedAt: item.updatedAt ?? new Date('2026-01-01T00:00:00.000Z'),
    });

    financialRecordRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      findByYearMonth: jest.fn().mockResolvedValue(null),
      save: jest.fn((item) =>
        Promise.resolve(stampTimestamps(item) as FinancialRecord),
      ),
    };

    service = new FinancialRecordsService(financialRecordRepository);
  });

  it('lists all records', async () => {
    await service.getRecords();
    expect(financialRecordRepository.findAll).toHaveBeenCalledWith();
  });

  it('creates a record and computes profit fields', async () => {
    const result = await service.createRecord({
      year: 2026,
      month: 1,
      revenueRs: '1000000.00',
      revenueUsd: '3571.43',
      expenseRs: '600000.00',
      expenseUsd: '2142.86',
      fxRate: '280.00',
    });

    expect(result.profitRs).toBeCloseTo(400000, 2);
    expect(result.profitUsd).toBeCloseTo(1428.57, 2);
    expect(result.profitPercent).toBeCloseTo(40, 2);
  });

  it('returns 0% profit when revenue is 0 instead of dividing by zero', async () => {
    const result = await service.createRecord({
      year: 2026,
      month: 1,
      revenueRs: '0',
      revenueUsd: '0',
      expenseRs: '0',
      expenseUsd: '0',
      fxRate: '280.00',
    });

    expect(result.profitPercent).toBe(0);
  });

  it('rejects creating a duplicate year/month', async () => {
    financialRecordRepository.findByYearMonth.mockResolvedValue(buildRecord());

    await expect(
      service.createRecord({
        year: 2026,
        month: 1,
        revenueRs: '1',
        revenueUsd: '1',
        expenseRs: '1',
        expenseUsd: '1',
        fxRate: '280.00',
      }),
    ).rejects.toThrow(ConflictException);
  });

  it('updates a record', async () => {
    financialRecordRepository.findById.mockResolvedValue(buildRecord());

    const result = await service.updateRecord('record-1', {
      revenueRs: '1200000.00',
    });

    expect(result.revenueRs).toBe(1200000);
  });

  it('rejects moving a record onto another record\'s year/month', async () => {
    financialRecordRepository.findById.mockResolvedValue(
      buildRecord({ id: 'record-1', year: 2026, month: 1 }),
    );
    financialRecordRepository.findByYearMonth.mockResolvedValue(
      buildRecord({ id: 'record-2', year: 2026, month: 2 }),
    );

    await expect(
      service.updateRecord('record-1', { month: 2 }),
    ).rejects.toThrow(ConflictException);
  });

  it('throws when updating a record that does not exist', async () => {
    financialRecordRepository.findById.mockResolvedValue(null);

    await expect(
      service.updateRecord('missing', { revenueRs: '1' }),
    ).rejects.toThrow(NotFoundException);
  });
});
