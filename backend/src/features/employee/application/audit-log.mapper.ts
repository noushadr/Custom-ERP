import { EmployeeAuditLog } from '../domain/entities/employee-audit-log.entity';
import { AuditLogResponse } from './audit-log-response.interface';

export function toAuditLogResponse(entry: EmployeeAuditLog): AuditLogResponse {
  return {
    id: entry.id,
    employeeName: entry.employee
      ? `${entry.employee.firstName} ${entry.employee.lastName}`.trim()
      : undefined,
    actorName: entry.actorName,
    fieldLabel: entry.fieldLabel,
    oldValue: entry.oldValue,
    newValue: entry.newValue,
    createdAt: entry.createdAt,
  };
}
