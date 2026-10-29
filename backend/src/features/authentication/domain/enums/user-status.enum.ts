export enum UserStatus {
  ACTIVE = 'active',
  PENDING_INVITE = 'pending_invite',
  /** Added by HR; cannot sign in until a Super Admin approves. */
  PENDING_APPROVAL = 'pending_approval',
  DISABLED = 'disabled',
}
