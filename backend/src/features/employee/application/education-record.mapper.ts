import { EducationRecord } from '../domain/entities/education-record.entity';
import { EducationRecordResponse } from './education-record-response.interface';

export function toEducationRecordResponse(
  record: EducationRecord,
): EducationRecordResponse {
  return {
    id: record.id,
    degree: record.degree,
    institution: record.institution,
    yearCompleted: record.yearCompleted,
    createdAt: record.createdAt,
  };
}
