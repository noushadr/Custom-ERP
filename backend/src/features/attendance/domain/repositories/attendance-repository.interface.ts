import { AttendanceWfhDay } from '../entities/attendance-wfh-day.entity';
import { AttendanceWfhPresence } from '../entities/attendance-wfh-presence.entity';
import { AttendanceDeviceUser } from '../entities/attendance-device-user.entity';
import { AttendancePunch } from '../entities/attendance-punch.entity';
import { AttendanceSettings } from '../entities/attendance-settings.entity';

export const ATTENDANCE_REPOSITORY = Symbol('ATTENDANCE_REPOSITORY');

export interface AttendanceRepository {
  /** Inserts punches, silently skipping ones already stored. Returns how
   * many were actually new. */
  insertPunches(
    punches: { deviceUserId: string; punchedAt: Date }[],
  ): Promise<number>;
  findPunches(
    deviceUserIds: string[],
    from: Date,
    to: Date,
  ): Promise<AttendancePunch[]>;
  replaceDeviceUsers(users: AttendanceDeviceUser[]): Promise<void>;
  findDeviceUsers(): Promise<AttendanceDeviceUser[]>;
  setDeviceUserIgnored(deviceUserId: string, ignored: boolean): Promise<boolean>;
  findWfhDays(from?: string, to?: string): Promise<AttendanceWfhDay[]>;
  findWfhDay(date: string): Promise<AttendanceWfhDay | null>;
  saveWfhDay(day: AttendanceWfhDay): Promise<AttendanceWfhDay>;
  /** Removes the day and everyone's manual presence on it. */
  deleteWfhDay(date: string): Promise<void>;
  findWfhPresence(from: string, to: string): Promise<AttendanceWfhPresence[]>;
  /** Replaces the set of employees marked present on [date]. */
  replaceWfhPresence(date: string, employeeIds: string[]): Promise<void>;
  /** One employee's own work-from-home mark on a date. */
  addWfhPresence(employeeId: string, date: string): Promise<void>;
  removeWfhPresence(employeeId: string, date: string): Promise<void>;
  getSettings(): Promise<AttendanceSettings>;
  saveSettings(settings: AttendanceSettings): Promise<AttendanceSettings>;
}
