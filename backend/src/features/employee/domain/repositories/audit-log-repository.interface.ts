import { EmployeeAuditLog } from '../entities/employee-audit-log.entity';

export const AUDIT_LOG_REPOSITORY = Symbol('AUDIT_LOG_REPOSITORY');

export interface AuditLogRepository {
  findByEmployeeId(employeeId: string): Promise<EmployeeAuditLog[]>;

  /** Most recent entries across all employees, newest first, with the
   * `employee` relation loaded. */
  findAll(limit: number): Promise<EmployeeAuditLog[]>;

  saveMany(entries: EmployeeAuditLog[]): Promise<EmployeeAuditLog[]>;
}
