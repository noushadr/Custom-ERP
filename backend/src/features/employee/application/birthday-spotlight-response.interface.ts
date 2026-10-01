import { UpcomingBirthdayResponse } from './upcoming-birthday-response.interface';

/** Every active employee's birthday falling in the current calendar month
 * or the next one, for the Admin Dashboard's Birthdays card. Grouped by
 * month rather than a single "last"/"upcoming" pair, since several people
 * can share a month. Each list is sorted by day-of-month ascending. */
export interface BirthdaySpotlightResponse {
  thisMonth: UpcomingBirthdayResponse[];
  nextMonth: UpcomingBirthdayResponse[];
}
