import { SalaryRecord } from '../entities/salary-record.entity';

export const SALARY_RECORD_REPOSITORY = Symbol('SALARY_RECORD_REPOSITORY');

export interface SalaryRecordRepository {
  /** Chronological, oldest first — the first entry is the joining salary,
   * the last is the current salary. */
  findByEmployeeId(employeeId: string): Promise<SalaryRecord[]>;
  findById(id: string): Promise<SalaryRecord | null>;
  save(record: SalaryRecord): Promise<SalaryRecord>;
  remove(record: SalaryRecord): Promise<void>;
}
