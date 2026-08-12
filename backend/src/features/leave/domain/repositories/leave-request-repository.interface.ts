import { LeaveRequest } from '../entities/leave-request.entity';
import { LeaveRequestStatus } from '../enums/leave-request-status.enum';

export const LEAVE_REQUEST_REPOSITORY = Symbol('LEAVE_REQUEST_REPOSITORY');

export interface LeaveRequestRepository {
  findById(id: string): Promise<LeaveRequest | null>;
  findByEmployeeId(employeeId: string): Promise<LeaveRequest[]>;
  findByStatus(status: LeaveRequestStatus): Promise<LeaveRequest[]>;
  findByStatuses(statuses: LeaveRequestStatus[]): Promise<LeaveRequest[]>;
  save(request: LeaveRequest): Promise<LeaveRequest>;
}
