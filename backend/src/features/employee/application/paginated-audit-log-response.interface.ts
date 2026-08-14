import { AuditLogResponse } from './audit-log-response.interface';

export interface PaginatedAuditLogResponse {
  items: AuditLogResponse[];
  total: number;
  page: number;
  limit: number;
}
