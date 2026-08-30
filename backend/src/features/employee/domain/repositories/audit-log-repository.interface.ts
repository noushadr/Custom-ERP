import { EmployeeAuditLog } from '../entities/employee-audit-log.entity';

export const AUDIT_LOG_REPOSITORY = Symbol('AUDIT_LOG_REPOSITORY');

export interface AuditLogSearchParams {
  page: number;
  limit: number;
  search?: string;
}

export interface AuditLogSearchResult {
  items: EmployeeAuditLog[];
  total: number;
}

export interface AuditLogRepository {
  findByEmployeeId(employeeId: string): Promise<EmployeeAuditLog[]>;

  /** Paginated, newest first, with the `employee` relation loaded. When
   * [AuditLogSearchParams.search] is set, matches across the employee's name,
   * the field label, old/new values, and the actor's name. */
  findAllPaginated(params: AuditLogSearchParams): Promise<AuditLogSearchResult>;

  /** Every change to [fieldLabel] recorded on or after [since], oldest
   * first — lets a caller reconstruct "what was this field's value as of
   * [since]" per employee by taking the first entry per `employeeId` (its
   * `oldValue` is the value immediately before the window started). */
  findFieldChangesSince(
    fieldLabel: string,
    since: Date,
  ): Promise<EmployeeAuditLog[]>;

  saveMany(entries: EmployeeAuditLog[]): Promise<EmployeeAuditLog[]>;
}
