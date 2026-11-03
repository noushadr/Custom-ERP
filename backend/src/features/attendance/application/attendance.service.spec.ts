import { BadRequestException, ConflictException } from '@nestjs/common';
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
      graceMinutes: 15,
    });
    repository = {
      insertPunches: jest.fn().mockResolvedValue(2),
      findPunches: jest.fn().mockResolvedValue([]),
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

    it('marks an approved leave day as leave rather than absent', async () => {
      employeeRepository.findAll.mockResolvedValue([
        employee({ id: 'e1', attendanceId: '48' }),
      ]);
      leave.getLeaveCalendar.mockResolvedValue([
        {
          employeeId: 'e1',
          startDate: '2026-10-06',
          endDate: '2026-10-06',
          isPending: false,
        },
      ]);

      const rows = await service.getCompanyMonth(10, 2026);

      expect(rows[0].days.find((d) => d.date === '2026-10-06')!.status).toBe(
        'leave',
      );
    });

    it('leaves remote employees out of the company report', async () => {
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

    it('refuses to link a remote employee, and auto-link skips them', async () => {
      const remote = employee({ id: 'e2', workMode: WorkMode.REMOTE });
      employeeRepository.findById.mockResolvedValue(remote);
      await expect(service.setMapping('e2', '19')).rejects.toBeInstanceOf(
        BadRequestException,
      );

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

  describe('updateSettings', () => {
    it('rejects a shift that ends before it starts', async () => {
      await expect(
        service.updateSettings({
          shiftStart: '19:00',
          shiftEnd: '11:00',
          graceMinutes: 15,
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });
});
