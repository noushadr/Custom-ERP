/** How long a notice stays visible after it is posted (or after its display
 * time is last changed). `ALWAYS` means it never expires. */
export enum NoticeDisplayDuration {
  ONE_DAY = 'one_day',
  THREE_DAYS = 'three_days',
  ONE_WEEK = 'one_week',
  TWO_WEEKS = 'two_weeks',
  ONE_MONTH = 'one_month',
  ALWAYS = 'always',
}

const DAYS_BY_DURATION: Record<NoticeDisplayDuration, number | null> = {
  [NoticeDisplayDuration.ONE_DAY]: 1,
  [NoticeDisplayDuration.THREE_DAYS]: 3,
  [NoticeDisplayDuration.ONE_WEEK]: 7,
  [NoticeDisplayDuration.TWO_WEEKS]: 14,
  // A month is a flat 30 days — a notice window doesn't need calendar-month
  // precision, and a fixed length is easier to reason about.
  [NoticeDisplayDuration.ONE_MONTH]: 30,
  [NoticeDisplayDuration.ALWAYS]: null,
};

/** The moment a notice stops showing, or null for one that never expires.
 * Always computed on the server from [from] (its own clock) — the client only
 * ever picks a preset, never supplies a timestamp. */
export function expiryDateFor(
  duration: NoticeDisplayDuration,
  from: Date,
): Date | null {
  const days = DAYS_BY_DURATION[duration];
  if (days === null) return null;
  return new Date(from.getTime() + days * 24 * 60 * 60 * 1000);
}
