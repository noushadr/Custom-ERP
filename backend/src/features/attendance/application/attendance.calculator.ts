/** Pure day-by-day attendance rules. All times are Pakistan time (the
 * machine and the office run on it) regardless of the server's own zone. */

export const ATTENDANCE_TIME_ZONE = 'Asia/Karachi';

/** Two scans closer together than this are one tap, not an in and an out. */
const MIN_SPAN_MINUTES = 30;

export type AttendanceDayStatus =
  | 'present'
  | 'late'
  | 'incomplete'
  | 'missing_checkin'
  | 'hours_cut'
  | 'wfh'
  | 'absent'
  | 'leave'
  | 'holiday'
  | 'weekend'
  | 'pending'
  | 'upcoming';

export interface AttendanceDay {
  /** yyyy-MM-dd */
  date: string;
  /** Mon..Sun */
  weekday: string;
  /** "HH:mm" or null */
  clockIn: string | null;
  clockOut: string | null;
  lateMinutes: number;
  /** How long after the end of the grace period they arrived, for late and
   * hours-cut days (what the daily table shows beside the clock-in time). */
  arrivalLateMinutes: number;
  earlyMinutes: number;
  /** Minutes stayed past the shift end (clock out after it). */
  extraMinutes: number;
  workMinutes: number;
  /** On an Hours Cut day: whole hours cut (a multiple of 60 minutes). */
  hoursCutMinutes: number;
  status: AttendanceDayStatus;
  /** Which kind of leave (Casual, Sick, Annual...) on a leave day. */
  leaveType: string | null;
}

export interface AttendanceShift {
  start: string;
  end: string;
  /** Arriving after this is an Hours Cut day, not a late mark. */
  hoursCutAfter: string;
  /** Whole hours are counted from this time on an Hours Cut day. */
  hoursCutFrom: string;
  graceMinutes: number;
}

const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

const partsFormatter = new Intl.DateTimeFormat('en-CA', {
  timeZone: ATTENDANCE_TIME_ZONE,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  hour12: false,
});

/** The Pakistan calendar date and minutes-since-midnight of an instant. */
export function karachiParts(instant: Date): { date: string; minutes: number } {
  const parts = Object.fromEntries(
    partsFormatter.formatToParts(instant).map((p) => [p.type, p.value]),
  );
  const hour = Number(parts.hour) % 24;
  return {
    date: `${parts.year}-${parts.month}-${parts.day}`,
    minutes: hour * 60 + Number(parts.minute),
  };
}

export function toMinutes(hhmm: string): number {
  const [h, m] = hhmm.split(':').map(Number);
  return h * 60 + m;
}

export function formatMinutes(total: number): string {
  const h = Math.floor(total / 60);
  const m = total % 60;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
}

export function weekdayOf(isoDate: string): string {
  return WEEKDAYS[new Date(`${isoDate}T00:00:00Z`).getUTCDay()];
}

export function isWeekendDate(isoDate: string): boolean {
  const day = new Date(`${isoDate}T00:00:00Z`).getUTCDay();
  return day === 0 || day === 6;
}

export interface ComputeDayInput {
  date: string;
  /** Minutes-since-midnight (Pakistan time) of each scan that day. */
  punchMinutes: number[];
  shift: AttendanceShift;
  isHoliday: boolean;
  isOnLeave: boolean;
  /** The approved leave's type, e.g. "Sick Leave" (when [isOnLeave]). */
  leaveType?: string | null;
  /** A company work-from-home day: scans are ignored, HR marks who worked. */
  isWfhDay?: boolean;
  /** HR marked this employee as having worked on the WFH day. */
  wfhPresent?: boolean;
  /** Today's date in Pakistan time. */
  today: string;
}

export function computeDay(input: ComputeDayInput): AttendanceDay {
  const { date, shift, today } = input;
  const base = {
    date,
    weekday: weekdayOf(date),
    clockIn: null,
    clockOut: null,
    lateMinutes: 0,
    arrivalLateMinutes: 0,
    earlyMinutes: 0,
    extraMinutes: 0,
    workMinutes: 0,
    hoursCutMinutes: 0,
    leaveType: null as string | null,
  };
  const weekend = isWeekendDate(date);

  // Work-from-home day: no machine attendance at all — no clock times, grace
  // or late hours. HR's manual mark makes it a plain worked/present day.
  // Weekends and public holidays stay exempt, and approved leave still wins.
  // It applies company-wide (isWfhDay) or to just this employee when HR
  // marked their own day (wfhPresent without a company day).
  if ((input.isWfhDay || input.wfhPresent) && !weekend && !input.isHoliday) {
    if (input.isOnLeave) {
      return {
        ...base,
        status: 'leave',
        leaveType: input.leaveType ?? null,
      };
    }
    if (input.wfhPresent) return { ...base, status: 'wfh' };
    let status: AttendanceDayStatus = 'absent';
    if (date > today) status = 'upcoming';
    else if (date === today) status = 'pending';
    return { ...base, status };
  }

  const sorted = [...input.punchMinutes].sort((a, b) => a - b);

  if (sorted.length === 0) {
    let status: AttendanceDayStatus;
    if (weekend) status = 'weekend';
    else if (input.isHoliday) status = 'holiday';
    else if (input.isOnLeave) {
      status = 'leave';
      return { ...base, status, leaveType: input.leaveType ?? null };
    }
    else if (date > today) status = 'upcoming';
    else if (date === today) status = 'pending';
    else status = 'absent';
    return { ...base, status };
  }

  const first = sorted[0];
  const last = sorted[sorted.length - 1];
  const hasOut = sorted.length > 1 && last - first >= MIN_SPAN_MINUTES;
  const clockIn = formatMinutes(first);
  const clockOut = hasOut ? formatMinutes(last) : null;
  const workMinutes = hasOut ? last - first : 0;

  // A lone scan after the middle of the shift is the evening clock-out with
  // the morning scan missed — not a very late arrival, so no late mark and
  // no hours cut. The person still came in (counts as present); HR can see
  // the day is flagged and sort out the hours by hand.
  const shiftMiddle = (toMinutes(shift.start) + toMinutes(shift.end)) / 2;
  if (!hasOut && first >= shiftMiddle && !weekend && !input.isHoliday) {
    return { ...base, clockOut: clockIn, status: 'missing_checkin' };
  }

  // Weekend/holiday work is just worked time: nothing can be "late" on a
  // day that wasn't a working day.
  const workingDay = !weekend && !input.isHoliday;
  const lateBy = first - toMinutes(shift.start);
  // Arriving after the cut-off isn't a late mark: the missed hours are cut
  // instead, and the day doesn't count toward the every-third-late rule.
  const hoursCut = workingDay && first > toMinutes(shift.hoursCutAfter);
  const late = workingDay && !hoursCut && lateBy > shift.graceMinutes;
  const earlyMinutes =
    workingDay && hasOut ? Math.max(0, toMinutes(shift.end) - last) : 0;
  const extraMinutes =
    workingDay && hasOut ? Math.max(0, last - toMinutes(shift.end)) : 0;

  let status: AttendanceDayStatus = 'present';
  if (hoursCut) status = 'hours_cut';
  else if (!hasOut && date < today) status = 'incomplete';
  else if (late) status = 'late';

  return {
    ...base,
    clockIn,
    clockOut,
    // Lateness is counted from the end of the grace period (start + grace):
    // arriving 2 minutes after it is "2m late", not 17.
    lateMinutes: late ? lateBy - shift.graceMinutes : 0,
    arrivalLateMinutes:
      late || hoursCut ? Math.max(0, lateBy - shift.graceMinutes) : 0,
    earlyMinutes,
    extraMinutes,
    workMinutes,
    // Straight hours only: minutes past the last whole hour are dropped
    // (arriving 11:45 with hours counted from 10:30 cuts 1 hour).
    hoursCutMinutes: hoursCut
      ? Math.max(0, Math.floor((first - toMinutes(shift.hoursCutFrom)) / 60)) *
        60
      : 0,
    status,
  };
}

/** Every this-many late days in a month costs one unpaid absence — five
 * for team leads. */
export const LATES_PER_UNPAID_ABSENCE = 3;
export const LATES_PER_UNPAID_ABSENCE_TEAM_LEAD = 5;

export interface AttendanceSummary {
  present: number;
  late: number;
  /** Unpaid absences earned by lates: one per third late day in the month. */
  lateDeductionDays: number;
  absent: number;
  leave: number;
  incomplete: number;
  /** Work-from-home days HR marked as worked. */
  wfhDays: number;
  /** Days arriving after the cut-off, and the hours cut across them. */
  hoursCutDays: number;
  hoursCutMinutes: number;
  lateMinutes: number;
  workMinutes: number;
}

export function summarize(
  days: AttendanceDay[],
  latesPerUnpaidAbsence: number = LATES_PER_UNPAID_ABSENCE,
): AttendanceSummary {
  const summary: AttendanceSummary = {
    present: 0,
    late: 0,
    lateDeductionDays: 0,
    absent: 0,
    leave: 0,
    incomplete: 0,
    wfhDays: 0,
    hoursCutDays: 0,
    hoursCutMinutes: 0,
    lateMinutes: 0,
    workMinutes: 0,
  };
  for (const day of days) {
    summary.lateMinutes += day.lateMinutes;
    summary.workMinutes += day.workMinutes;
    // Anyone who came in counts as present — with or without a check-out.
    if (
      day.status === 'present' ||
      day.status === 'late' ||
      day.status === 'incomplete' ||
      day.status === 'missing_checkin' ||
      day.status === 'hours_cut' ||
      day.status === 'wfh'
    ) {
      summary.present++;
    }
    // A late arrival is a late day even when they never checked out.
    if (day.lateMinutes > 0) summary.late++;
    if (day.status === 'incomplete') summary.incomplete++;
    if (day.status === 'wfh') summary.wfhDays++;
    if (day.status === 'hours_cut') {
      summary.hoursCutDays++;
      summary.hoursCutMinutes += day.hoursCutMinutes;
    }
    if (day.status === 'absent') summary.absent++;
    else if (day.status === 'leave') summary.leave++;
  }
  summary.lateDeductionDays = Math.floor(
    summary.late / latesPerUnpaidAbsence,
  );
  return summary;
}
