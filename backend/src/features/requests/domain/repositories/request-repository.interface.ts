import { EmployeeRequest } from '../entities/employee-request.entity';
import { RequestStatus } from '../enums/request-status.enum';

export const REQUEST_REPOSITORY = Symbol('REQUEST_REPOSITORY');

export interface RequestRepository {
  findById(id: string): Promise<EmployeeRequest | null>;
  findByEmployeeId(employeeId: string): Promise<EmployeeRequest[]>;
  findByStatus(status: RequestStatus): Promise<EmployeeRequest[]>;
  save(request: EmployeeRequest): Promise<EmployeeRequest>;
}
