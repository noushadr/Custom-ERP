export enum RequestKind {
  GENERAL = 'general',
  PROFILE_CHANGE = 'profile_change',
  /** A Team Lead nominating one of their own direct reports for Employee of
   * the Month. Skips the manager-approval step the same way PROFILE_CHANGE
   * does — the submitter already *is* the nominee's reporting manager, so
   * there's no separate manager to approve it — and goes straight to
   * HR/Admin. See `EmployeeRequest.nomineeEmployeeId`. */
  EMPLOYEE_OF_MONTH_NOMINATION = 'employee_of_month_nomination',
  /** No longer created — item requests were merged into GENERAL 2026-08-30
   * so "request an item" and "new request" are one single feature, both
   * going through the same Manager-then-HR approval workflow. Kept here
   * (not migrated away) purely so any pre-existing rows still deserialize
   * correctly; never set by any current code path. */
  ITEM = 'item',
}
