import { LeaveRequest } from '../domain/entities/leave-request.entity';
import { LeaveRequestResponse } from './leave-request-response.interface';

export function toLeaveRequestResponse(
  request: LeaveRequest,
): LeaveRequestResponse {
  return {
    id: request.id,
    employeeId: request.employeeId,
    requesterName: `${request.employee.firstName} ${request.employee.lastName}`,
    requesterPhotoUrl: request.employee.profilePhotoUrl ?? null,
    leaveTypeId: request.leaveTypeId,
    leaveTypeName: request.leaveType.name,
    startDate: request.startDate,
    endDate: request.endDate,
    numberOfDays: request.numberOfDays,
    reason: request.reason,
    status: request.status,
    managerDecisionAt: request.managerDecisionAt?.toISOString() ?? null,
    managerDecisionByName: request.managerDecisionByName ?? null,
    managerComment: request.managerComment ?? null,
    hrDecisionAt: request.hrDecisionAt?.toISOString() ?? null,
    hrDecisionByName: request.hrDecisionByName ?? null,
    hrComment: request.hrComment ?? null,
    cancelledAt: request.cancelledAt?.toISOString() ?? null,
    createdAt: request.createdAt.toISOString(),
  };
}
