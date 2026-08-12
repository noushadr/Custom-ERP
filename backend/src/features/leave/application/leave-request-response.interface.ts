import { LeaveRequestStatus } from '../domain/enums/leave-request-status.enum';

export interface LeaveRequestResponse {
  id: string;
  employeeId: string;
  requesterName: string;
  requesterPhotoUrl: string | null;
  leaveTypeId: string;
  leaveTypeName: string;
  startDate: string;
  endDate: string;
  numberOfDays: string;
  reason: string;
  status: LeaveRequestStatus;
  managerDecisionAt: string | null;
  managerDecisionByName: string | null;
  managerComment: string | null;
  hrDecisionAt: string | null;
  hrDecisionByName: string | null;
  hrComment: string | null;
  cancelledAt: string | null;
  createdAt: string;
}
