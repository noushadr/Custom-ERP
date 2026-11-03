/** Pure day-by-day attendance rules. All times are Pakistan time (the
 * machine and the office run on it) regardless of the server's own zone. */

export const ATTENDANCE_TIME_ZONE = 'Asia/Karachi';

/** Two scans closer together than this are one tap, not an in and an out. */
const MIN_SPAN_MINUTES = 30;

export type AttendanceDayStatus =
  | 'present'
  | 'late'
  | 'incomplete'
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
  earlyMinutes: number;
  workMinutes: number;
  status: AttendanceDayStatus;
}

export interface AttendanceShift {
  start: string;
  end: string;
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
    earlyMinutes: 0,
    workMinutes: 0,
  };
  const weekend = isWeekendDate(date);
  const sorted = [...input.punchMinutes].sort((a, b) => a - b);

  if (sorted.length === 0) {
    let status: AttendanceDayStatus;
    if (weekend) status = 'weekend';
    else if (input.isHoliday) status = 'holiday';
    else if (input.isOnLeave) status = 'leave';
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

  // Weekend/holiday work is just worked time: nothing can be "late" on a
  // day that wasn't a working day.
  const workingDay = !weekend && !input.isHoliday;
  const lateBy = first - toMinutes(shift.start);
  const late = workingDay && lateBy > shift.graceMinutes;
  const earlyMinutes =
    workingDay && hasOut ? Math.max(0, toMinutes(shift.end) - last) : 0;

  let status: AttendanceDayStatus = 'present';
  if (!hasOut && date < today) status = 'incomplete';
  else if (late) status = 'late';

  return {
    ...base,
    clockIn,
    clockOut,
    lateMinutes: late ? lateBy : 0,
    earlyMinutes,
    workMinutes,
    status,
  };
}

export interface AttendanceSummary {
  present: number;
  late: number;
  absent: number;
  leave: number;
  incomplete: number;
  lateMinutes: number;
  workMinutes: number;
}

export function summarize(days: AttendanceDay[]): AttendanceSummary {
  const summary: AttendanceSummary = {
    present: 0,
    late: 0,
    absent: 0,
    leave: 0,
    incomplete: 0,
    lateMinutes: 0,
    workMinutes: 0,
  };
  for (const day of days) {
    summary.lateMinutes += day.lateMinutes;
    summary.workMinutes += day.workMinutes;
    if (day.status === 'present') summary.present++;
    else if (day.status === 'late') {
      summary.present++;
      summary.late++;
    } else if (day.status === 'incomplete') {
      summary.present++;
      summary.incomplete++;
    } else if (day.status === 'absent') summary.absent++;
    else if (day.status === 'leave') summary.leave++;
  }
  return summary;
}
