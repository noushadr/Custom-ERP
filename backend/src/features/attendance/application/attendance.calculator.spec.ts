import {
  AttendanceShift,
  computeDay,
  karachiParts,
  summarize,
} from './attendance.calculator';

const shift: AttendanceShift = {
  start: '11:00',
  end: '19:00',
  graceMinutes: 15,
};
const m = (h: number, min = 0) => h * 60 + min;

const day = (over: Partial<Parameters<typeof computeDay>[0]> = {}) =>
  computeDay({
    date: '2026-10-05', // a Monday
    punchMinutes: [],
    shift,
    isHoliday: false,
    isOnLeave: false,
    today: '2026-11-03',
    ...over,
  });

describe('computeDay', () => {
  it('takes the first scan as clock in and the last as clock out', () => {
    const d = day({ punchMinutes: [m(10, 42), m(13), m(18, 26)] });
    expect(d.clockIn).toBe('10:42');
    expect(d.clockOut).toBe('18:26');
    expect(d.workMinutes).toBe(m(18, 26) - m(10, 42));
    expect(d.status).toBe('present');
    expect(d.earlyMinutes).toBe(34);
  });

  it('marks late only after the grace period', () => {
    expect(day({ punchMinutes: [m(11, 15), m(19)] }).status).toBe('present');
    const late = day({ punchMinutes: [m(11, 30), m(19)] });
    expect(late.status).toBe('late');
    expect(late.lateMinutes).toBe(30);
  });

  it('treats two scans seconds apart as one tap, with no clock out', () => {
    const d = day({ punchMinutes: [m(10, 40), m(10, 41)] });
    expect(d.clockOut).toBeNull();
    expect(d.status).toBe('incomplete');
  });

  it('is absent on a past working day with no scans, but not on a weekend', () => {
    expect(day().status).toBe('absent');
    expect(day({ date: '2026-10-03' }).status).toBe('weekend');
  });

  it('prefers holiday and leave over absent', () => {
    expect(day({ isHoliday: true }).status).toBe('holiday');
    expect(day({ isOnLeave: true }).status).toBe('leave');
  });

  it('leaves today and the future pending', () => {
    expect(day({ date: '2026-11-03' }).status).toBe('pending');
    expect(day({ date: '2026-11-04' }).status).toBe('upcoming');
  });

  it('never calls weekend work late', () => {
    const d = day({ date: '2026-10-03', punchMinutes: [m(15), m(18)] });
    expect(d.status).toBe('present');
    expect(d.lateMinutes).toBe(0);
  });
});

describe('karachiParts', () => {
  it('reads the Pakistan date and time of an instant', () => {
    // 20:30 UTC on the 4th is 01:30 on the 5th in Pakistan (UTC+5).
    expect(karachiParts(new Date('2026-10-04T20:30:00Z'))).toEqual({
      date: '2026-10-05',
      minutes: m(1, 30),
    });
  });
});

describe('summarize', () => {
  it('counts late days as present too', () => {
    const days = [
      day({ punchMinutes: [m(11, 30), m(19)] }),
      day({ punchMinutes: [m(10, 50), m(19)] }),
      day(),
    ];
    const s = summarize(days);
    expect(s.present).toBe(2);
    expect(s.late).toBe(1);
    expect(s.absent).toBe(1);
  });
});
