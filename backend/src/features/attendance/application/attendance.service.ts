import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { EMPLOYEE_REPOSITORY } from '../../employee/domain/repositories/employee-repository.interface';
import type { EmployeeRepository } from '../../employee/domain/repositories/employee-repository.interface';
import { Employee } from '../../employee/domain/entities/employee.entity';
import { EmploymentStatus } from '../../employee/domain/enums/employment-status.enum';
import { WorkMode } from '../../employee/domain/enums/work-mode.enum';
import { HolidaysService } from '../../holidays/application/holidays.service';
import { LeaveService } from '../../leave/application/leave.service';
import { AttendanceDeviceUser } from '../domain/entities/attendance-device-user.entity';
import { AttendanceSettings } from '../domain/entities/attendance-settings.entity';
import {
  ATTENDANCE_REPOSITORY,
  type AttendanceRepository,
} from '../domain/repositories/attendance-repository.interface';
import {
  AttendanceMappingResponse,
  AttendanceSettingsResponse,
  EmployeeAttendanceResponse,
  SyncResultResponse,
} from './attendance-response.interface';
import {
  AttendanceShift,
  computeDay,
  karachiParts,
  summarize,
  toMinutes,
} from './attendance.calculator';
import { UpdateAttendanceSettingsDto } from './dto/attendance.dto';
import { ATTENDANCE_DEVICE, type AttendanceDevice } from './zk-device.client';

function pad(n: number): string {
  return String(n).padStart(2, '0');
}

function normalizeName(name: string): string {
  return name.toLowerCase().replace(/\s+/g, ' ').trim();
}

@Injectable()
export class AttendanceService {
  private readonly logger = new Logger(AttendanceService.name);
  private syncing = false;

  constructor(
    @Inject(ATTENDANCE_REPOSITORY)
    private readonly repository: AttendanceRepository,
    @Inject(ATTENDANCE_DEVICE) private readonly device: AttendanceDevice,
    @Inject(EMPLOYEE_REPOSITORY)
    private readonly employeeRepository: EmployeeRepository,
    private readonly holidaysService: HolidaysService,
    private readonly leaveService: LeaveService,
  ) {}

  // ---------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------

  async getSettings(): Promise<AttendanceSettingsResponse> {
    return this.toSettingsResponse(await this.repository.getSettings());
  }

  async updateSettings(
    dto: UpdateAttendanceSettingsDto,
  ): Promise<AttendanceSettingsResponse> {
    if (toMinutes(dto.shiftEnd) <= toMinutes(dto.shiftStart)) {
      throw new BadRequestException('The shift must end after it starts');
    }
    const settings = await this.repository.getSettings();
    settings.shiftStart = dto.shiftStart;
    settings.shiftEnd = dto.shiftEnd;
    settings.graceMinutes = dto.graceMinutes;
    return this.toSettingsResponse(await this.repository.saveSettings(settings));
  }

  private toSettingsResponse(
    settings: AttendanceSettings,
  ): AttendanceSettingsResponse {
    return {
      shiftStart: settings.shiftStart,
      shiftEnd: settings.shiftEnd,
      graceMinutes: settings.graceMinutes,
      lastSyncAt: settings.lastSyncAt?.toISOString() ?? null,
      lastSyncMessage: settings.lastSyncMessage ?? null,
      deviceConfigured: this.device.isConfigured(),
    };
  }

  // ---------------------------------------------------------------------
  // Machine sync
  // ---------------------------------------------------------------------

  /** Pulls every scan from the machine and stores the ones not seen before.
   * Safe to run repeatedly: stored scans are never duplicated. */
  async syncFromDevice(): Promise<SyncResultResponse> {
    if (!this.device.isConfigured()) {
      throw new BadRequestException('No attendance machine is configured');
    }
    if (this.syncing) {
      throw new ConflictException('A sync is already running');
    }
    this.syncing = true;
    const settings = await this.repository.getSettings();
    try {
      const { users, punches } = await this.device.readAll();
      const inserted = await this.repository.insertPunches(
        punches.map((p) => ({ deviceUserId: p.userId, punchedAt: p.time })),
      );
      const deviceUsers = users.map((u) => {
        const entity = new AttendanceDeviceUser();
        entity.deviceUserId = u.userId;
        entity.name = u.name;
        return entity;
      });
      await this.repository.replaceDeviceUsers(deviceUsers);

      settings.lastSyncAt = new Date();
      settings.lastSyncMessage = `OK — ${inserted} new scan(s)`;
      await this.repository.saveSettings(settings);
      return { fetched: punches.length, inserted, users: users.length };
    } catch (error) {
      settings.lastSyncAt = new Date();
      settings.lastSyncMessage = 'Could not reach the attendance machine';
      await this.repository.saveSettings(settings);
      this.logger.warn(
        `Attendance sync failed: ${error instanceof Error ? error.message : String(error)}`,
      );
      throw new BadRequestException(
        'Could not reach the attendance machine. Check it is on and on the same network.',
      );
    } finally {
      this.syncing = false;
    }
  }

  /** Keeps the data fresh without anyone pressing Sync. */
  @Cron('*/10 * * * *')
  async handleScheduledSync(): Promise<void> {
    if (!this.device.isConfigured() || this.syncing) return;
    try {
      await this.syncFromDevice();
    } catch {
      // Already logged and recorded as the last sync's message.
    }
  }

  // ---------------------------------------------------------------------
  // Linking machine users to employees
  // ---------------------------------------------------------------------

  async getMapping(): Promise<AttendanceMappingResponse[]> {
    const [deviceUsers, employees] = await Promise.all([
      this.repository.findDeviceUsers(),
      this.employeeRepository.findAll(),
    ]);
    const byAttendanceId = new Map(
      employees
        .filter((e) => e.attendanceId)
        .map((e) => [e.attendanceId as string, e]),
    );
    return deviceUsers
      .map((u) => {
        const employee = byAttendanceId.get(u.deviceUserId);
        return {
          deviceUserId: u.deviceUserId,
          deviceName: u.name,
          employeeId: employee?.id ?? null,
          employeeName: employee
            ? `${employee.firstName} ${employee.lastName}`
            : null,
          ignored: u.ignored,
        };
      })
      .sort((a, b) => Number(a.deviceUserId) - Number(b.deviceUserId));
  }

  /** Marks a machine user as someone who no longer works here (or back). */
  async setDeviceUserIgnored(
    deviceUserId: string,
    ignored: boolean,
  ): Promise<void> {
    if (!(await this.repository.setDeviceUserIgnored(deviceUserId, ignored))) {
      throw new NotFoundException('Machine user not found');
    }
  }

  async setMapping(
    employeeId: string,
    deviceUserId: string | null | undefined,
  ): Promise<void> {
    const employee = await this.employeeRepository.findById(employeeId);
    if (!employee) throw new NotFoundException('Employee not found');
    if (deviceUserId && employee.workMode === WorkMode.REMOTE) {
      throw new BadRequestException(
        'Remote employees are not tracked on the attendance machine',
      );
    }

    const wanted = deviceUserId?.trim() || null;
    if (wanted) {
      const all = await this.employeeRepository.findAll();
      const taken = all.find(
        (e) => e.attendanceId === wanted && e.id !== employeeId,
      );
      if (taken) {
        throw new ConflictException(
          `That machine user is already linked to ${taken.firstName} ${taken.lastName}`,
        );
      }
    }
    employee.attendanceId = wanted;
    await this.employeeRepository.save(employee);
  }

  /** Links machine users to employees whose full name matches exactly (case
   * and spacing aside). Anything ambiguous or unmatched is left for HR. */
  async autoMap(): Promise<{ linked: number }> {
    const [deviceUsers, employees] = await Promise.all([
      this.repository.findDeviceUsers(),
      this.employeeRepository.findAll(),
    ]);
    const taken = new Set(
      employees.map((e) => e.attendanceId).filter((id): id is string => !!id),
    );
    const open = employees.filter(
      (e) =>
        !e.attendanceId &&
        e.employmentStatus === EmploymentStatus.ACTIVE &&
        e.workMode !== WorkMode.REMOTE,
    );
    let linked = 0;
    for (const user of deviceUsers) {
      if (user.ignored || taken.has(user.deviceUserId)) continue;
      const name = normalizeName(user.name);
      if (!name) continue;
      let matches = open.filter(
        (e) => normalizeName(`${e.firstName} ${e.lastName}`) === name,
      );
      if (matches.length === 0) {
        // The machine often holds a shorter name ("Asad Rathore") than the
        // employee record ("Muhammad Asad Rathore"): accept it when every
        // word of it appears in exactly one open employee's name.
        const words = name.split(' ');
        if (words.length >= 2) {
          matches = open.filter((e) => {
            const full = normalizeName(`${e.firstName} ${e.lastName}`).split(' ');
            return words.every((w) => full.includes(w));
          });
        }
      }
      if (matches.length !== 1) continue;
      matches[0].attendanceId = user.deviceUserId;
      await this.employeeRepository.save(matches[0]);
      open.splice(open.indexOf(matches[0]), 1);
      taken.add(user.deviceUserId);
      linked++;
    }
    return { linked };
  }

  // ---------------------------------------------------------------------
  // Reports
  // ---------------------------------------------------------------------

  /** Everyone's month — HR/Admin only (the controller guards it). */
  async getCompanyMonth(
    month: number,
    year: number,
  ): Promise<EmployeeAttendanceResponse[]> {
    this.assertMonth(month, year);
    const employees = (await this.employeeRepository.findAll())
      .filter(
        (e) =>
          e.employmentStatus === EmploymentStatus.ACTIVE &&
          e.workMode !== WorkMode.REMOTE,
      )
      .sort((a, b) =>
        `${a.firstName} ${a.lastName}`.localeCompare(
          `${b.firstName} ${b.lastName}`,
        ),
      );
    return this.buildMonth(employees, month, year);
  }

  async getEmployeeMonth(
    employeeId: string,
    month: number,
    year: number,
  ): Promise<EmployeeAttendanceResponse> {
    this.assertMonth(month, year);
    const employee = await this.employeeRepository.findById(employeeId);
    if (!employee) throw new NotFoundException('Employee not found');
    return (await this.buildMonth([employee], month, year))[0];
  }

  async getMyMonth(
    actorUserId: string,
    month: number,
    year: number,
  ): Promise<EmployeeAttendanceResponse> {
    const me = await this.employeeRepository.findByUserId(actorUserId);
    if (!me) throw new NotFoundException('No employee profile for this user');
    return this.getEmployeeMonth(me.id, month, year);
  }

  private assertMonth(month: number, year: number): void {
    if (
      !Number.isInteger(month) ||
      month < 1 ||
      month > 12 ||
      !Number.isInteger(year) ||
      year < 2000 ||
      year > 2100
    ) {
      throw new BadRequestException('Choose a valid month and year');
    }
  }

  private async buildMonth(
    employees: Employee[],
    month: number,
    year: number,
  ): Promise<EmployeeAttendanceResponse[]> {
    const settings = await this.repository.getSettings();
    const shift: AttendanceShift = {
      start: settings.shiftStart,
      end: settings.shiftEnd,
      graceMinutes: settings.graceMinutes,
    };

    const daysInMonth = new Date(Date.UTC(year, month, 0)).getUTCDate();
    const dates = Array.from(
      { length: daysInMonth },
      (_, i) => `${year}-${pad(month)}-${pad(i + 1)}`,
    );
    // Pakistan has no daylight saving, so a fixed +05:00 offset is exact.
    const from = new Date(`${dates[0]}T00:00:00+05:00`);
    const to = new Date(`${dates[dates.length - 1]}T23:59:59.999+05:00`);

    const linked = employees.filter((e) => e.attendanceId);
    const [punches, holidayDates, leaveEntries] = await Promise.all([
      this.repository.findPunches(
        linked.map((e) => e.attendanceId as string),
        from,
        to,
      ),
      this.holidaysService.getDatesInRange(dates[0], dates[dates.length - 1]),
      this.leaveService.getLeaveCalendar('', 'company', month, year, true),
    ]);
    const holidays = new Set(holidayDates);

    const minutesByUserDay = new Map<string, number[]>();
    for (const punch of punches) {
      const { date, minutes } = karachiParts(punch.punchedAt);
      const key = `${punch.deviceUserId}|${date}`;
      const list = minutesByUserDay.get(key);
      if (list) list.push(minutes);
      else minutesByUserDay.set(key, [minutes]);
    }

    const leaveDays = new Set<string>();
    for (const entry of leaveEntries) {
      if (entry.isPending) continue;
      for (const date of dates) {
        if (date >= entry.startDate && date <= entry.endDate) {
          leaveDays.add(`${entry.employeeId}|${date}`);
        }
      }
    }

    const today = karachiParts(new Date()).date;

    return employees.map((employee) => {
      const days = employee.attendanceId && employee.workMode !== WorkMode.REMOTE
        ? dates.map((date) =>
            computeDay({
              date,
              punchMinutes:
                minutesByUserDay.get(`${employee.attendanceId}|${date}`) ?? [],
              shift,
              isHoliday: holidays.has(date),
              isOnLeave: leaveDays.has(`${employee.id}|${date}`),
              today,
            }),
          )
        : [];
      return {
        employeeId: employee.id,
        employeeName: `${employee.firstName} ${employee.lastName}`,
        employeeCode: employee.employeeCode,
        profilePhotoUrl: employee.profilePhotoUrl ?? null,
        linked: !!employee.attendanceId,
        remote: employee.workMode === WorkMode.REMOTE,
        days,
        summary: summarize(days),
      };
    });
  }
}
