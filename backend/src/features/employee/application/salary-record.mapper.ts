import { SalaryRecord } from '../domain/entities/salary-record.entity';
import { SalaryRecordResponse } from './salary-record-response.interface';

export function toSalaryRecordResponse(
  record: SalaryRecord,
): SalaryRecordResponse {
  return {
    id: record.id,
    amount: record.amount,
    effectiveDate: record.effectiveDate,
    note: record.note ?? null,
    createdAt: record.createdAt,
  };
}
