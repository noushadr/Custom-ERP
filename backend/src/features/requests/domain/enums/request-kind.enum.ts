export enum RequestKind {
  GENERAL = 'general',
  PROFILE_CHANGE = 'profile_change',
  /** No longer created — item requests were merged into GENERAL 2026-08-30
   * so "request an item" and "new request" are one single feature, both
   * going through the same Manager-then-HR approval workflow. Kept here
   * (not migrated away) purely so any pre-existing rows still deserialize
   * correctly; never set by any current code path. */
  ITEM = 'item',
}
