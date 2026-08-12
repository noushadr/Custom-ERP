export interface LeaveBalanceResponse {
  leaveTypeId: string;
  leaveTypeName: string;
  colorHex: string | null;
  year: number;
  allocated: number;
  used: number;
  remaining: number;
}
