import { EmployeeDocument } from '../entities/employee-document.entity';

export const DOCUMENT_REPOSITORY = Symbol('DOCUMENT_REPOSITORY');

export interface DocumentRepository {
  findByEmployeeId(employeeId: string): Promise<EmployeeDocument[]>;
  findById(id: string): Promise<EmployeeDocument | null>;
  save(document: EmployeeDocument): Promise<EmployeeDocument>;
  remove(document: EmployeeDocument): Promise<void>;
}
