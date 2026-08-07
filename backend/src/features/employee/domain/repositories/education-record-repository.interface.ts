import { EducationRecord } from '../entities/education-record.entity';

export const EDUCATION_RECORD_REPOSITORY = Symbol(
  'EDUCATION_RECORD_REPOSITORY',
);

export interface EducationRecordRepository {
  /** Chronological, oldest first. */
  findByEmployeeId(employeeId: string): Promise<EducationRecord[]>;
  findById(id: string): Promise<EducationRecord | null>;
  save(record: EducationRecord): Promise<EducationRecord>;
  remove(record: EducationRecord): Promise<void>;
}
