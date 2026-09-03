import { Injectable } from '@nestjs/common';
import { EmployeesService } from '../../employee/application/employees.service';
import { HolidaysService } from '../../holidays/application/holidays.service';
import { NoticesService } from '../../notices/application/notices.service';
import type { TodayAnnouncementsResponse } from './interfaces/today-announcements-response.interface';

/** Same "local calendar day" comparison `EmployeesService`'s own
 * closestAnnualOccurrence/birthday-anniversary logic uses (plain
 * `Date` getters, not `toISOString`), so a notice posted late in the day
 * lines up with what "today" means everywhere else in this app. */
function todayIso(): string {
  const now = new Date();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  return `${now.getFullYear()}-${month}-${day}`;
}

/** Powers the top-bar announcement banner — a same-day-only slice of data
 * that already exists elsewhere (birthdays/anniversaries, Public Holidays,
 * Company Notices), aggregated into one call so the banner (mounted once,
 * globally, in the app shell) doesn't fire three separate requests on every
 * page load. Deliberately open to every authenticated employee, not gated by
 * `employees.manage` like the HR-only "Celebrations" feed the bell already
 * has — a birthday/anniversary/holiday shoutout is meant for the whole
 * company to see, not just HR. */
@Injectable()
export class AnnouncementsService {
  constructor(
    private readonly employeesService: EmployeesService,
    private readonly holidaysService: HolidaysService,
    private readonly noticesService: NoticesService,
  ) {}

  async getToday(): Promise<TodayAnnouncementsResponse> {
    const today = todayIso();

    const [birthdays, workAnniversaries, holidays, notices] =
      await Promise.all([
        this.employeesService.getUpcomingBirthdays(0, 0),
        this.employeesService.getUpcomingWorkAnniversaries(0, 0),
        this.holidaysService.getAll(new Date().getFullYear()),
        this.noticesService.findAll(),
      ]);

    const holidayToday = holidays.find((h) => h.date === today) ?? null;

    return {
      birthdays: birthdays.map((b) => ({
        employeeId: b.employeeId,
        fullName: b.fullName,
        profilePhotoUrl: b.profilePhotoUrl,
      })),
      workAnniversaries: workAnniversaries.map((a) => ({
        employeeId: a.employeeId,
        fullName: a.fullName,
        profilePhotoUrl: a.profilePhotoUrl,
        yearsOfService: a.yearsOfService,
      })),
      holiday: holidayToday
        ? { name: holidayToday.name, date: holidayToday.date }
        : null,
      notices: notices
        .filter((n) => todayIsoFromDate(n.createdAt) === today)
        .map((n) => ({ id: n.id, title: n.title, authorName: n.authorName })),
    };
  }
}

function todayIsoFromDate(date: Date): string {
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${date.getFullYear()}-${month}-${day}`;
}
