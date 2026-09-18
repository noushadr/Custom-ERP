import { UpcomingWorkAnniversaryResponse } from './upcoming-work-anniversary-response.interface';

/** Every active employee whose next work anniversary falls in the same
 * calendar month as the soonest one — unlike birthdays (always exactly one
 * "upcoming" person), a work-anniversary month can genuinely have several
 * employees hitting theirs together. Empty when nobody has an upcoming
 * anniversary on file. */
export interface WorkAnniversarySpotlightResponse {
  anniversaries: UpcomingWorkAnniversaryResponse[];
}
