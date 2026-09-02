import { EmployeeRequest } from '../domain/entities/employee-request.entity';
import { RequestResponse } from './request-response.interface';

export function toRequestResponse(request: EmployeeRequest): RequestResponse {
  return {
    id: request.id,
    requesterId: request.employeeId,
    requesterName: `${request.employee.firstName} ${request.employee.lastName}`,
    requesterPhotoUrl: request.employee.profilePhotoUrl ?? null,
    subject: request.subject,
    description: request.description,
    type: request.type ?? null,
    kind: request.kind,
    status: request.status,
    managerDecisionAt: request.managerDecisionAt?.toISOString() ?? null,
    managerDecisionByName: request.managerDecisionByName ?? null,
    hrDecisionAt: request.hrDecisionAt?.toISOString() ?? null,
    hrDecisionByName: request.hrDecisionByName ?? null,
    rejectionReason: request.rejectionReason ?? null,
    createdAt: request.createdAt.toISOString(),
  };
}
