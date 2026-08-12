import { LeaveBalanceAdjustment } from '../entities/leave-balance-adjustment.entity';

export const LEAVE_BALANCE_ADJUSTMENT_REPOSITORY = Symbol(
  'LEAVE_BALANCE_ADJUSTMENT_REPOSITORY',
);

export interface LeaveBalanceAdjustmentRepository {
  findByEmployeeId(employeeId: string): Promise<LeaveBalanceAdjustment[]>;
  save(adjustment: LeaveBalanceAdjustment): Promise<LeaveBalanceAdjustment>;
}
