import { LeaveType } from '../entities/leave-type.entity';

export const LEAVE_TYPE_REPOSITORY = Symbol('LEAVE_TYPE_REPOSITORY');

export interface LeaveTypeRepository {
  findAll(includeArchived?: boolean): Promise<LeaveType[]>;
  findById(id: string): Promise<LeaveType | null>;
  save(leaveType: LeaveType): Promise<LeaveType>;
  remove(leaveType: LeaveType): Promise<void>;
}
