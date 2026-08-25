import {
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { definedFieldsOnly } from '../../../core/utils/defined-fields-only.util';
import { FinancialRecord } from '../domain/entities/financial-record.entity';
import {
  FINANCIAL_RECORD_REPOSITORY,
  type FinancialRecordRepository,
} from '../domain/repositories/financial-record-repository.interface';
import { CreateFinancialRecordDto } from './dto/create-financial-record.dto';
import { UpdateFinancialRecordDto } from './dto/update-financial-record.dto';
import { FinancialRecordResponseDto } from './financial-record-response.interface';
import { toFinancialRecordResponse } from './financial-record.mapper';

@Injectable()
export class FinancialRecordsService {
  constructor(
    @Inject(FINANCIAL_RECORD_REPOSITORY)
    private readonly financialRecordRepository: FinancialRecordRepository,
  ) {}

  async getRecords(): Promise<FinancialRecordResponseDto[]> {
    const records = await this.financialRecordRepository.findAll();
    return records.map(toFinancialRecordResponse);
  }

  async createRecord(
    dto: CreateFinancialRecordDto,
  ): Promise<FinancialRecordResponseDto> {
    const existing = await this.financialRecordRepository.findByYearMonth(
      dto.year,
      dto.month,
    );
    if (existing) {
      throw new ConflictException(
        `A financial record for ${dto.month}/${dto.year} already exists.`,
      );
    }

    const record = new FinancialRecord();
    record.year = dto.year;
    record.month = dto.month;
    record.revenueRs = dto.revenueRs;
    record.revenueUsd = dto.revenueUsd;
    record.expenseRs = dto.expenseRs;
    record.expenseUsd = dto.expenseUsd;
    record.fxRate = dto.fxRate;

    const saved = await this.financialRecordRepository.save(record);
    return toFinancialRecordResponse(saved);
  }

  async updateRecord(
    id: string,
    dto: UpdateFinancialRecordDto,
  ): Promise<FinancialRecordResponseDto> {
    const record = await this.financialRecordRepository.findById(id);
    if (!record) throw new NotFoundException('Financial record not found');

    const changes = definedFieldsOnly(dto);
    if (
      (changes.year !== undefined && changes.year !== record.year) ||
      (changes.month !== undefined && changes.month !== record.month)
    ) {
      const year = changes.year ?? record.year;
      const month = changes.month ?? record.month;
      const existing = await this.financialRecordRepository.findByYearMonth(
        year,
        month,
      );
      if (existing && existing.id !== record.id) {
        throw new ConflictException(
          `A financial record for ${month}/${year} already exists.`,
        );
      }
    }

    Object.assign(record, changes);
    const saved = await this.financialRecordRepository.save(record);
    return toFinancialRecordResponse(saved);
  }
}
