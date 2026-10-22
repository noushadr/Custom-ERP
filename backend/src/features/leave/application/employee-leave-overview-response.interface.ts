import { LeaveBalanceResponse } from './leave-balance-response.interface';

/** One row of the HR/Admin "all employees' leave" table: an active
 * employee's current-year balance for every (non-archived) leave type, plus
 * the same figures summed across types. */
export interface EmployeeLeaveOverviewResponse {
  employeeId: string;
  employeeCode: string;
  employeeName: string;
  departmentName: string | null;
  profilePhotoUrl: string | null;
  balances: LeaveBalanceResponse[];
  totalAllocated: number;
  totalUsed: number;
  totalRemaining: number;
}
