import { UpcomingBirthdayResponse } from './upcoming-birthday-response.interface';

/** The single most-recently-passed and single soonest-upcoming birthday
 * among active employees — for the Admin Dashboard's "Last Birthday"/
 * "Upcoming Birthday" cards. Either side is `null` when no active employee
 * has a `dateOfBirth` on file in that direction. */
export interface BirthdaySpotlightResponse {
  last: UpcomingBirthdayResponse | null;
  upcoming: UpcomingBirthdayResponse | null;
}
