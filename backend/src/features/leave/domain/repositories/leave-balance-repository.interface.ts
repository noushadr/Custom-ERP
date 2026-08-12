import { LeaveBalance } from '../entities/leave-balance.entity';

export const LEAVE_BALANCE_REPOSITORY = Symbol('LEAVE_BALANCE_REPOSITORY');

export interface LeaveBalanceRepository {
  findOne(
    employeeId: string,
    leaveTypeId: string,
    year: number,
  ): Promise<LeaveBalance | null>;
  findByEmployeeId(employeeId: string): Promise<LeaveBalance[]>;
  findByYear(year: number): Promise<LeaveBalance[]>;
  save(balance: LeaveBalance): Promise<LeaveBalance>;
  saveMany(balances: LeaveBalance[]): Promise<LeaveBalance[]>;
}
