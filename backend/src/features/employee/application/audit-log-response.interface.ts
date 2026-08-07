export interface AuditLogResponse {
  id: string;
  /** Only populated on the company-wide feed — the per-employee endpoints
   * don't load this relation since the employee is already implied by context. */
  employeeName?: string;
  actorName: string;
  fieldLabel: string;
  oldValue: string | null;
  newValue: string | null;
  createdAt: Date;
}
