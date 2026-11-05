import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { Employee } from '../../employee/domain/entities/employee.entity';
import { EmploymentStatus } from '../../employee/domain/enums/employment-status.enum';
import { WorkMode } from '../../employee/domain/enums/work-mode.enum';
import { AttendanceSettings } from '../domain/entities/attendance-settings.entity';
import { AttendanceService } from './attendance.service';
import { AttendanceDevice } from './zk-device.client';

function employee(over: Partial<Employee> = {}): Employee {
  return {
    id: 'e1',
    firstName: 'Jane',
    lastName: 'Doe',
    employeeCode: 'ZC-1',
    attendanceId: null,
    employmentStatus: EmploymentStatus.ACTIVE,
    ...over,
  } as Employee;
}

describe('AttendanceService', () => {
  let service: AttendanceService;
  let repository: {
    insertPunches: jest.Mock;
    findPunches: jest.Mock;
    findWfhDays: jest.Mock;
    findWfhDay: jest.Mock;
    saveWfhDay: jest.Mock;
    deleteWfhDay: jest.Mock;
    findWfhPresence: jest.Mock;
    replaceWfhPresence: jest.Mock;
    addWfhPresence: jest.Mock;
    removeWfhPresence: jest.Mock;
    replaceDeviceUsers: jest.Mock;
    findDeviceUsers: jest.Mock;
    getSettings: jest.Mock;
    saveSettings: jest.Mock;
  };
  let device: jest.Mocked<AttendanceDevice>;
  let employeeRepository: { findAll: jest.Mock; findById: jest.Mock; save: jest.Mock };
  let holidays: { getDatesInRange: jest.Mock };
  let leave: { getLeaveCalendar: jest.Mock };

  beforeEach(() => {
    const settings = Object.assign(new AttendanceSettings(), {
      id: 1,
      shiftStart: '11:00',
      shiftEnd: '19:00',
      hoursCutAfter: '11:30',
      hoursCutFrom: '10:30',
      graceMinutes: 15,
    });
    repository = {
      insertPunches: jest.fn().mockResolvedValue(2),
      findPunches: jest.fn().mockResolvedValue([]),
      findWfhDays: jest.fn().mockResolvedValue([]),
      findWfhDay: jest.fn().mockResolvedValue(null),
      saveWfhDay: jest.fn((d) => Promise.resolve(d)),
      deleteWfhDay: jest.fn(),
      findWfhPresence: jest.fn().mockResolvedValue([]),
      replaceWfhPresence: jest.fn(),
      addWfhPresence: jest.fn(),
      removeWfhPresence: jest.fn(),
      replaceDeviceUsers: jest.fn(),
      findDeviceUsers: jest.fn().mockResolvedValue([]),
      getSettings: jest.fn().mockResolvedValue(settings),
      saveSettings: jest.fn((s) => Promise.resolve(s)),
    };
    device = {
      isConfigured: jest.fn().mockReturnValue(true),
      readAll: jest.fn().mockResolvedValue({
        users: [{ userId: '48', name: 'Jane Doe' }],
        punches: [
          { userId: '48', time: new Date('2026-10-05T05:42:00Z') },
          { userId: '48', time: new Date('2026-10-05T13:26:00Z') },
        ],
      }),
    };
    employeeRepository = {
      findAll: jest.fn().mockResolvedValue([employee()]),
      findById: jest.fn().mockResolvedValue(employee()),
      save: jest.fn((e) => Promise.resolve(e)),
    };
    holidays = { getDatesInRange: jest.fn().mockResolvedValue([]) };
    leave = { getLeaveCalendar: jest.fn().mockResolvedValue([]) };
    service = new AttendanceService(
      repository as never,
      device,
      employeeRepository as never,
      holidays as never,
      leave as never,
    );
  });

  describe('syncFromDevice', () => {
    it('stores the scans and the enrolled users, and records the outcome', async () => {
      const result = await service.syncFromDevice();

      expect(result).toEqual({ fetched: 2, inserted: 2, users: 1 });
      expect(repository.insertPunches).toHaveBeenCalledWith([
        { deviceUserId: '48', punchedAt: new Date('2026-10-05T05:42:00Z') },
        { deviceUserId: '48', punchedAt: new Date('2026-10-05T13:26:00Z') },
      ]);
      expect(repository.replaceDeviceUsers).toHaveBeenCalled();
      expect(repository.saveSettings).toHaveBeenCalledWith(
        expect.objectContaining({ lastSyncMessage: 'OK — 2 new scan(s)' }),
      );
    });

    it('refuses when no machine is configured', async () => {
      device.isConfigured.mockReturnValue(false);
      await expect(service.syncFromDevice()).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('turns a machine failure into a friendly error and records it', async () => {
      device.readAll.mockRejectedValue(new Error('ETIMEDOUT'));
      await expect(service.syncFromDevice()).rejects.toBeInstanceOf(
        BadRequestException,
      );
      expect(repository.saveSettings).toHaveBeenCalledWith(
        expect.objectContaining({
          lastSyncMessage: 'Could not reach the attendance machine',
        }),
      );
    });
  });

  describe('refreshIfStale', () => {
    it('syncs when the last sync is old or failed', async () => {
      const result = await service.refreshIfStale();
      expect(result.skipped).toBeUndefined();
      expect(device.readAll).toHaveBeenCalledTimes(1);
    });

    it('skips when a sync succeeded a moment ago', async () => {
      const settings = await repository.getSettings();
      settings.lastSyncAt = new Date();
      settings.lastSyncMessage = 'OK - 0 new scan(s)';

      const result = await service.refreshIfStale();

      expect(result.skipped).toBe(true);
      expect(device.readAll).not.toHaveBeenCalled();
    });

    it('still tries again when the last attempt failed, even a moment ago', async () => {
      const settings = await repository.getSettings();
      settings.lastSyncAt = new Date();
      settings.lastSyncMessage = 'Could not reach the attendance machine';

      await service.refreshIfStale();

      expect(device.readAll).toHaveBeenCalledTimes(1);
    });
  });

  describe('linking machine users', () => {
    it('refuses a machine user already linked to someone else', async () => {
      employeeRepository.findAll.mockResolvedValue([
        employee({ id: 'e1', attendanceId: '48' }),
        employee({ id: 'e2' }),
      ]);
      employeeRepository.findById.mockResolvedValue(employee({ id: 'e2' }));
      await expect(service.setMapping('e2', '48')).rejects.toBeInstanceOf(
        ConflictException,
      );
    });

    it('auto-links exact names, and a shorter machine name inside one employee name', async () => {
      repository.findDeviceUsers.mockResolvedValue([
        { deviceUserId: '1', name: 'Jane Doe' },
        { deviceUserId: '2', name: 'Asad Rathore' },
        { deviceUserId: '3', name: 'Nobody Known' },
      ]);
      const jane = employee({ id: 'e1' });
      const asad = employee({
        id: 'e2',
        firstName: 'Muhammad Asad',
        lastName: 'Rathore',
      });
      employeeRepository.findAll.mockResolvedValue([jane, asad]);

      const result = await service.autoMap();

      expect(result.linked).toBe(2);
      expect(jane.attendanceId).toBe('1');
      expect(asad.attendanceId).toBe('2');
    });

    it('does not guess when a short name fits two employees', async () => {
      repository.findDeviceUsers.mockResolvedValue([
        { deviceUserId: '2', name: 'Ali Khan' },
      ]);
      employeeRepository.findAll.mockResolvedValue([
        employee({ id: 'a', firstName: 'Ali Raza', lastName: 'Khan' }),
        employee({ id: 'b', firstName: 'Ali Hassan', lastName: 'Khan' }),
      ]);
      expect((await service.autoMap()).linked).toBe(0);
    });
  });

  describe('getCompanyMonth', () => {
    it('builds each linked employee a day-by-day month from their scans', async () => {
      employeeRepository.findAll.mockResolvedValue([
        employee({ id: 'e1', attendanceId: '48' }),
        employee({ id: 'e2', firstName: 'No', lastName: 'Link' }),
      ]);
      repository.findPunches.mockResolvedValue([
        { deviceUserId: '48', punchedAt: new Date('2026-10-05T05:42:00Z') },
        { deviceUserId: '48', punchedAt: new Date('2026-10-05T13:26:00Z') },
      ]);

      const rows = await service.getCompanyMonth(10, 2026);

      const jane = rows.find((r) => r.employeeId === 'e1')!;
      expect(jane.days).toHaveLength(31);
      const day = jane.days.find((d) => d.date === '2026-10-05')!;
      expect(day.clockIn).toBe('10:42');
      expect(day.clockOut).toBe('18:26');
      expect(rows.find((r) => r.employeeId === 'e2')!.linked).toBe(false);
    });

    it('charges HR (Zahra) per five lates too', async () => {
      employeeRepository.findAll.mockResolvedValue([
        employee({
          id: 'hr',
          firstName: 'Zahra',
          lastName: 'HR',
          attendanceId: '10',
          user: { role: { name: 'HR/Manager' } },
        } as never),
      ]);
      repository.findPunches.mockResolvedValue(
        [5, 6, 7, 8].flatMap((day) => [
          {
            deviceUserId: '10',
            punchedAt: new Date(`2026-10-0${day}T06:25:00Z`),
          },
          {
            deviceUserId: '10',
            punchedAt: new Date(`2026-10-0${day}T14:00:00Z`),
          },
        ]),
      );

      const rows = await service.getCompanyMonth(10, 2026);

      expect(rows[0].summary.late).toBe(4);
      expect(rows[0].summary.lateDeductionDays).toBe(0);
    });

    it('charges a team lead per five lates and everyone else per three', async () => {
      const lateScans = (userId: string) =>
        [5, 6, 7, 8].flatMap((day) => [
          // In at 11:25 Pakistan time (late) and out at 19:00, Oct 5-8.
          {
            deviceUserId: userId,
            punchedAt: new Date(`2026-10-0${day}T06:25:00Z`),
          },
          {
            deviceUserId: userId,
            punchedAt: new Date(`2026-10-0${day}T14:00:00Z`),
          },
        ]);
      employeeRepository.findAll.mockResolvedValue([
        employee({
          id: 'lead',
          firstName: 'Team',
          lastName: 'Lead',
          attendanceId: '10',
          user: { role: { name: 'Team Lead' } },
        } as never),
        employee({
          id: 'staff',
          firstName: 'Plain',
          lastName: 'Staff',
          attendanceId: '11',
          user: { role: { name: 'Employee' } },
        } as never),
      ]);
      repository.findPunches.mockResolvedValue([
        ...lateScans('10'),
        ...lateScans('11'),
      ]);

      const rows = await service.getCompanyMonth(10, 2026);
      const byId = Object.fromEntries(rows.map((r) => [r.employeeId, r]));

      // Four late days: past the third for staff, short of the fifth for a lead.
      expect(byId.lead.summary.late).toBe(4);
      expect(byId.lead.summary.lateDeductionDays).toBe(0);
      expect(byId.staff.summary.late).toBe(4);
      expect(byId.staff.summary.lateDeductionDays).toBe(1);
    });

    it('marks an approved leave day as leave rather than absent', async () => {
      employeeRepository.findAll.mockResolvedValue([
        employee({ id: 'e1', attendanceId: '48' }),
      ]);
      leave.getLeaveCalendar.mockResolvedValue([
        {
          employeeId: 'e1',
          startDate: '2026-10-06',
          endDate: '2026-10-06',
          leaveTypeName: 'Sick Leave',
          isPending: false,
        },
      ]);

      const rows = await service.getCompanyMonth(10, 2026);

      const leaveDay = rows[0].days.find((d) => d.date === '2026-10-06')!;
      expect(leaveDay.status).toBe('leave');
      expect(leaveDay.leaveType).toBe('Sick Leave');
    });

    it('leaves unlinked remote employees out of the company report', async () => {
      employeeRepository.findAll.mockResolvedValue([
        employee({ id: 'e1', attendanceId: '48' }),
        employee({
          id: 'e2',
          firstName: 'Work',
          lastName: 'FromHome',
          workMode: WorkMode.REMOTE,
        }),
      ]);

      const rows = await service.getCompanyMonth(10, 2026);

      expect(rows.map((r) => r.employeeId)).toEqual(['e1']);
    });

    it('includes a remote employee HR has deliberately linked', async () => {
      employeeRepository.findAll.mockResolvedValue([
        employee({
          id: 'e2',
          firstName: 'Sometimes',
          lastName: 'InOffice',
          workMode: WorkMode.REMOTE,
          attendanceId: '69',
        }),
      ]);

      const rows = await service.getCompanyMonth(10, 2026);

      expect(rows).toHaveLength(1);
      expect(rows[0].linked).toBe(true);
      expect(rows[0].days).toHaveLength(31);
    });

    it('can link a remote employee by hand, but auto-link skips them', async () => {
      const remote = employee({ id: 'e2', workMode: WorkMode.REMOTE });
      employeeRepository.findById.mockResolvedValue(remote);
      employeeRepository.findAll.mockResolvedValue([remote]);
      await service.setMapping('e2', '19');
      expect(remote.attendanceId).toBe('19');
      remote.attendanceId = null;

      repository.findDeviceUsers.mockResolvedValue([
        { deviceUserId: '19', name: 'Jane Doe', ignored: false },
      ]);
      employeeRepository.findAll.mockResolvedValue([remote]);
      expect((await service.autoMap()).linked).toBe(0);
    });

    it('rejects an invalid month', async () => {
      await expect(service.getCompanyMonth(13, 2026)).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });
  });

  describe('work-from-home announcements', () => {
    afterEach(() => jest.useRealTimers());

    it('tells the viewer about a company day today and their own day tomorrow', async () => {
      jest.useFakeTimers().setSystemTime(new Date('2026-11-12T05:00:00Z'));
      employeeRepository.findByUserId = jest
        .fn()
        .mockResolvedValue(employee({ id: 'me', attendanceId: '48' }));
      repository.findWfhDays.mockResolvedValue([
        { date: '2026-11-12', note: 'Power cut' },
      ]);
      repository.findWfhPresence.mockResolvedValue([
        { employeeId: 'me', date: '2026-11-13' },
      ]);

      const result = await service.getWfhAnnouncement('user-1');

      expect(result.today).toEqual({ personal: false, note: 'Power cut' });
      expect(result.tomorrow).toEqual({ personal: true, note: null });
    });

    it('has nothing when no day is marked', async () => {
      employeeRepository.findByUserId = jest.fn().mockResolvedValue(null);
      const result = await service.getWfhAnnouncement('user-1');
      expect(result).toEqual({ today: null, tomorrow: null });
    });
  });

  describe('one person working from home', () => {
    it('lets HR mark and unmark a tracked employee on a weekday', async () => {
      employeeRepository.findById.mockResolvedValue(
        employee({ id: 'e1', attendanceId: '48' }),
      );

      await service.markEmployeeWfh('e1', '2026-11-12');
      expect(repository.addWfhPresence).toHaveBeenCalledWith('e1', '2026-11-12');

      await service.unmarkEmployeeWfh('e1', '2026-11-12');
      expect(repository.removeWfhPresence).toHaveBeenCalledWith(
        'e1',
        '2026-11-12',
      );
    });

    it('refuses weekends, holidays and people not on the machine', async () => {
      employeeRepository.findById.mockResolvedValue(
        employee({ id: 'e1', attendanceId: '48' }),
      );
      await expect(
        service.markEmployeeWfh('e1', '2026-11-14'),
      ).rejects.toBeInstanceOf(BadRequestException);

      holidays.getDatesInRange.mockResolvedValueOnce(['2026-11-12']);
      await expect(
        service.markEmployeeWfh('e1', '2026-11-12'),
      ).rejects.toBeInstanceOf(BadRequestException);

      employeeRepository.findById.mockResolvedValue(
        employee({ id: 'e2', attendanceId: null }),
      );
      await expect(
        service.markEmployeeWfh('e2', '2026-11-12'),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('shows that day as work from home for that person only', async () => {
      employeeRepository.findAll.mockResolvedValue([
        employee({ id: 'e1', attendanceId: '48' }),
        employee({
          id: 'e2',
          firstName: 'Other',
          lastName: 'Person',
          attendanceId: '49',
        }),
      ]);
      repository.findWfhPresence.mockResolvedValue([
        { employeeId: 'e1', date: '2026-10-07' },
      ]);

      const rows = await service.getCompanyMonth(10, 2026);
      const dayOf = (id: string) =>
        rows
          .find((r) => r.employeeId === id)!
          .days.find((d) => d.date === '2026-10-07')!;

      expect(dayOf('e1').status).toBe('wfh');
      expect(dayOf('e2').status).toBe('absent');
    });
  });

  describe('work from home days', () => {
    it('adds a weekday, and refuses weekends, holidays and repeats', async () => {
      const added = await service.addWfhDay({
        date: '2026-11-12',
        note: ' Power cut ',
      });
      expect(added).toEqual({
        date: '2026-11-12',
        note: 'Power cut',
        presentCount: 0,
      });

      await expect(
        service.addWfhDay({ date: '2026-11-14' }), // a Saturday
      ).rejects.toBeInstanceOf(BadRequestException);

      holidays.getDatesInRange.mockResolvedValueOnce(['2026-11-12']);
      await expect(
        service.addWfhDay({ date: '2026-11-12' }),
      ).rejects.toBeInstanceOf(BadRequestException);

      repository.findWfhDay.mockResolvedValueOnce({ date: '2026-11-12' });
      await expect(
        service.addWfhDay({ date: '2026-11-12' }),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('lets HR mark tracked employees present, ignoring anyone untracked', async () => {
      repository.findWfhDay.mockResolvedValue({ date: '2026-11-12' });
      employeeRepository.findAll.mockResolvedValue([
        employee({ id: 'tracked', attendanceId: '48' }),
        employee({ id: 'untracked', firstName: 'No', lastName: 'Link' }),
      ]);

      await service.setWfhDayAttendance('2026-11-12', [
        'tracked',
        'untracked',
        'tracked',
      ]);

      expect(repository.replaceWfhPresence).toHaveBeenCalledWith(
        '2026-11-12',
        ['tracked'],
      );
    });

    it('turns a work-from-home day into present days for the people HR marked', async () => {
      employeeRepository.findAll.mockResolvedValue([
        employee({ id: 'e1', attendanceId: '48' }),
        employee({
          id: 'e2',
          firstName: 'Not',
          lastName: 'Marked',
          attendanceId: '49',
        }),
      ]);
      repository.findWfhDays.mockResolvedValue([{ date: '2026-10-07' }]);
      repository.findWfhPresence.mockResolvedValue([
        { employeeId: 'e1', date: '2026-10-07' },
      ]);
      // A late scan on the WFH day must not matter.
      repository.findPunches.mockResolvedValue([
        { deviceUserId: '48', punchedAt: new Date('2026-10-07T08:00:00Z') },
        { deviceUserId: '48', punchedAt: new Date('2026-10-07T14:00:00Z') },
      ]);

      const rows = await service.getCompanyMonth(10, 2026);
      const byId = Object.fromEntries(rows.map((r) => [r.employeeId, r]));
      const dayOf = (id: string) =>
        byId[id].days.find((d) => d.date === '2026-10-07')!;

      expect(dayOf('e1').status).toBe('wfh');
      expect(dayOf('e1').lateMinutes).toBe(0);
      expect(dayOf('e2').status).toBe('absent');
      expect(byId.e1.summary.wfhDays).toBe(1);
    });

    it('refuses to mark attendance on a day that is not a work-from-home day', async () => {
      await expect(
        service.setWfhDayAttendance('2026-11-12', []),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  describe('updateSettings', () => {
    it('rejects a shift that ends before it starts', async () => {
      await expect(
        service.updateSettings({
          shiftStart: '19:00',
          shiftEnd: '11:00',
          hoursCutAfter: '11:30',
          hoursCutFrom: '10:30',
          graceMinutes: 15,
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });
});
