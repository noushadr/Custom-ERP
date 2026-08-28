import { FinancialRecord } from '../entities/financial-record.entity';

export const FINANCIAL_RECORD_REPOSITORY = Symbol(
  'FINANCIAL_RECORD_REPOSITORY',
);

export interface FinancialRecordRepository {
  findAll(): Promise<FinancialRecord[]>;
  findById(id: string): Promise<FinancialRecord | null>;
  findByYearMonth(year: number, month: number): Promise<FinancialRecord | null>;
  save(record: FinancialRecord): Promise<FinancialRecord>;
}
