/** The fixed catalog of automation types for V1 — each admin-toggleable
 * with configurable parameters (see Automation entity), but the underlying
 * trigger/condition logic per type is fixed code, not user-composable.
 * Deliberately NOT a generic rule builder (trigger+condition+action from
 * scratch) — a small, known set of use cases doesn't justify that scope.
 *
 * Deferred (not built): invoice/payment reminders (overlaps Finances'
 * outstanding-invoices tracking) and recurring report emails (needs
 * email-sending infrastructure that doesn't exist yet). */
export enum AutomationType {
  PROJECT_RENEWAL_REMINDER = 'project_renewal_reminder',
  TASK_DEADLINE_REMINDER = 'task_deadline_reminder',
  ANNUAL_LEAVE_RESET = 'annual_leave_reset',
}
