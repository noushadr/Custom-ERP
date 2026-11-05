import {
  AttendanceShift,
  computeDay,
  karachiParts,
  summarize,
} from './attendance.calculator';

const shift: AttendanceShift = {
  start: '11:00',
  end: '19:00',
  hoursCutAfter: '11:30',
  hoursCutFrom: '10:30',
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
    // Counted from the end of the grace period (11:15), not the shift start.
    expect(late.lateMinutes).toBe(15);
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

describe('computeDay — a lone evening scan', () => {
  it('is a missing check-in: present, but no late mark and no hours cut', () => {
    const d = day({ punchMinutes: [m(18, 32)] });
    expect(d.status).toBe('missing_checkin');
    expect(d.clockIn).toBeNull();
    expect(d.clockOut).toBe('18:32');
    expect(d.lateMinutes).toBe(0);
    expect(d.hoursCutMinutes).toBe(0);
    const s = summarize([d]);
    expect(s.present).toBe(1);
    expect(s.late).toBe(0);
    expect(s.hoursCutMinutes).toBe(0);
  });

  it('also covers several taps of the same evening', () => {
    const d = day({ punchMinutes: [m(18, 29), m(18, 29), m(18, 30)] });
    expect(d.status).toBe('missing_checkin');
  });

  it('still treats a lone morning scan as an arrival', () => {
    expect(day({ punchMinutes: [m(11, 25)] }).status).toBe('incomplete');
    expect(day({ punchMinutes: [m(12)] }).status).toBe('hours_cut');
  });

  it('leaves a normal in-and-out day alone', () => {
    expect(day({ punchMinutes: [m(14, 53), m(18, 25)] }).status).toBe(
      'hours_cut',
    );
  });
});

describe('computeDay — no check-out and hours cut', () => {
  it('counts a late arrival as late even with no check-out', () => {
    const d = day({ punchMinutes: [m(11, 25)] });
    expect(d.status).toBe('incomplete');
    expect(d.lateMinutes).toBe(10); // 11:25 is 10 minutes past 11:15
    const s = summarize([d]);
    expect(s.present).toBe(1);
    expect(s.late).toBe(1);
    expect(s.incomplete).toBe(1);
  });

  it('counts an on-time day with no check-out as present, not late', () => {
    const s = summarize([day({ punchMinutes: [m(10, 50)] })]);
    expect(s.present).toBe(1);
    expect(s.late).toBe(0);
  });

  it('makes arriving after the cut-off an Hours Cut day, not a late mark', () => {
    const d = day({ punchMinutes: [m(12, 10), m(19)] });
    expect(d.status).toBe('hours_cut');
    expect(d.lateMinutes).toBe(0);
    // 12:10 is 1h40 after 10:30: straight hours only, so one hour.
    expect(d.hoursCutMinutes).toBe(60);
    const s = summarize([d]);
    expect(s.present).toBe(1);
    expect(s.late).toBe(0);
    expect(s.hoursCutDays).toBe(1);
    expect(s.hoursCutMinutes).toBe(60);
  });

  it('cuts whole hours counted from 10:30, dropping the minutes', () => {
    const cut = (h: number, min: number) =>
      day({ punchMinutes: [m(h, min), m(19)] }).hoursCutMinutes;
    expect(cut(11, 45)).toBe(60); // 1h15 past 10:30 -> 1 hour
    expect(cut(11, 31)).toBe(60); // just past the cut-off -> 1 hour
    expect(cut(12, 29)).toBe(60); // 1h59 -> still 1 hour
    expect(cut(12, 30)).toBe(120); // exactly 2h -> 2 hours
    expect(cut(13, 5)).toBe(150 - 30); // 2h35 -> 2 hours
  });

  it('keeps 11:16 to 11:30 as an ordinary late mark', () => {
    expect(day({ punchMinutes: [m(11, 30), m(19)] }).status).toBe('late');
    expect(day({ punchMinutes: [m(11, 31), m(19)] }).status).toBe('hours_cut');
  });

  it('keeps hours-cut days out of the every-third-late count', () => {
    const lates = [1, 2].map(() => day({ punchMinutes: [m(11, 25), m(19)] }));
    const cut = day({ punchMinutes: [m(12, 30), m(19)] });
    expect(summarize([...lates, cut]).lateDeductionDays).toBe(0);
  });

  it('never cuts hours on a weekend', () => {
    const d = day({ date: '2026-10-03', punchMinutes: [m(15), m(18)] });
    expect(d.status).toBe('present');
    expect(d.hoursCutMinutes).toBe(0);
  });
});

describe('computeDay — weekends and holidays are exempt', () => {
  it('never marks a weekend or public holiday as absent or leave', () => {
    // Saturday and Sunday, even with approved leave covering them.
    for (const date of ['2026-10-03', '2026-10-04']) {
      expect(day({ date }).status).toBe('weekend');
      expect(day({ date, isOnLeave: true, leaveType: 'Sick' }).status).toBe(
        'weekend',
      );
    }
    // A public holiday on a weekday, with or without leave on top of it.
    expect(day({ isHoliday: true }).status).toBe('holiday');
    expect(
      day({ isHoliday: true, isOnLeave: true, leaveType: 'Annual' }).status,
    ).toBe('holiday');
  });

  it('counts none of those days as absent or leave in the totals', () => {
    const days = [
      day({ date: '2026-10-03', isOnLeave: true }),
      day({ date: '2026-10-04' }),
      day({ isHoliday: true, isOnLeave: true }),
    ];
    const s = summarize(days);
    expect(s.absent).toBe(0);
    expect(s.leave).toBe(0);
  });
});

describe('computeDay — how late, counted after the grace period', () => {
  it('reports minutes past start + grace, for late and hours-cut days only', () => {
    // Shift 11:00 + 15 min grace: lateness starts at 11:15.
    expect(day({ punchMinutes: [m(11, 17), m(19)] }).arrivalLateMinutes).toBe(2);
    expect(day({ punchMinutes: [m(11, 25), m(19)] }).arrivalLateMinutes).toBe(10);
    expect(day({ punchMinutes: [m(12, 10), m(19)] }).arrivalLateMinutes).toBe(55);
    expect(day({ punchMinutes: [m(11, 10), m(19)] }).arrivalLateMinutes).toBe(0); // within grace
    expect(day({ punchMinutes: [m(10, 50), m(19)] }).arrivalLateMinutes).toBe(0);
  });
});

describe('computeDay — time stayed after the shift end', () => {
  it('reports the minutes past the shift end as extra time', () => {
    expect(day({ punchMinutes: [m(10, 50), m(19, 25)] }).extraMinutes).toBe(25);
    expect(day({ punchMinutes: [m(10, 50), m(19)] }).extraMinutes).toBe(0);
    expect(day({ punchMinutes: [m(10, 50), m(18, 30)] }).extraMinutes).toBe(0);
  });

  it('has none without a check-out, or on a weekend', () => {
    expect(day({ punchMinutes: [m(10, 50)] }).extraMinutes).toBe(0);
    expect(
      day({ date: '2026-10-03', punchMinutes: [m(15), m(21)] }).extraMinutes,
    ).toBe(0);
  });
});

describe('computeDay — one person works from home', () => {
  it('is a plain worked day for just that employee, with no company WFH day', () => {
    const d = day({ wfhPresent: true, punchMinutes: [m(13), m(15)] });
    expect(d.status).toBe('wfh');
    expect(d.clockIn).toBeNull();
    expect(d.lateMinutes).toBe(0);
    expect(d.hoursCutMinutes).toBe(0);
  });

  it('still defers to weekends, holidays and approved leave', () => {
    expect(day({ date: '2026-10-03', wfhPresent: true }).status).toBe('weekend');
    expect(day({ isHoliday: true, wfhPresent: true }).status).toBe('holiday');
    expect(day({ isOnLeave: true, wfhPresent: true }).status).toBe('leave');
  });
});

describe('computeDay — work from home days', () => {
  const wfh = (over: Partial<Parameters<typeof computeDay>[0]> = {}) =>
    day({ isWfhDay: true, ...over });

  it('is a plain worked day when HR marked the employee — no times at all', () => {
    const d = wfh({ wfhPresent: true });
    expect(d.status).toBe('wfh');
    expect(d.clockIn).toBeNull();
    expect(d.clockOut).toBeNull();
    expect(d.lateMinutes).toBe(0);
    expect(d.earlyMinutes).toBe(0);
    expect(d.hoursCutMinutes).toBe(0);
  });

  it('ignores machine scans entirely, so nobody can be late or hours-cut', () => {
    const d = wfh({ wfhPresent: true, punchMinutes: [m(13, 30), m(15)] });
    expect(d.status).toBe('wfh');
    expect(d.lateMinutes).toBe(0);
    expect(d.hoursCutMinutes).toBe(0);
  });

  it('counts as present, and adds to the work-from-home total', () => {
    const s = summarize([wfh({ wfhPresent: true })]);
    expect(s.present).toBe(1);
    expect(s.wfhDays).toBe(1);
    expect(s.late).toBe(0);
  });

  it('is absent when HR did not mark them, once the day has passed', () => {
    expect(wfh().status).toBe('absent');
    expect(wfh({ date: '2026-11-03' }).status).toBe('pending');
    expect(wfh({ date: '2026-11-04' }).status).toBe('upcoming');
  });

  it('still lets approved leave win, and keeps weekends and holidays exempt', () => {
    expect(wfh({ isOnLeave: true, leaveType: 'Sick' }).status).toBe('leave');
    expect(wfh({ date: '2026-10-03', wfhPresent: true }).status).toBe(
      'weekend',
    );
    expect(wfh({ isHoliday: true, wfhPresent: true }).status).toBe('holiday');
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

describe('summarize — late deduction', () => {
  const lates = (n: number) =>
    Array.from({ length: n }, () =>
      day({ punchMinutes: [m(11, 25), m(19)] }),
    );

  it('charges one unpaid absence for every third late day', () => {
    expect(summarize(lates(2)).lateDeductionDays).toBe(0);
    expect(summarize(lates(3)).lateDeductionDays).toBe(1);
    expect(summarize(lates(5)).lateDeductionDays).toBe(1);
    expect(summarize(lates(6)).lateDeductionDays).toBe(2);
    expect(summarize(lates(12)).lateDeductionDays).toBe(4);
  });

  it('is one per fifth late day for team leads', () => {
    expect(summarize(lates(4), 5).lateDeductionDays).toBe(0);
    expect(summarize(lates(5), 5).lateDeductionDays).toBe(1);
    expect(summarize(lates(9), 5).lateDeductionDays).toBe(1);
    expect(summarize(lates(10), 5).lateDeductionDays).toBe(2);
  });

  it('does not count on-time days toward it', () => {
    const days = [...lates(2), day({ punchMinutes: [m(10, 50), m(19)] })];
    expect(summarize(days).lateDeductionDays).toBe(0);
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
