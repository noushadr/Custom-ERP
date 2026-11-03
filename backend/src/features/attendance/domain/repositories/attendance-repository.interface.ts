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
  getSettings(): Promise<AttendanceSettings>;
  saveSettings(settings: AttendanceSettings): Promise<AttendanceSettings>;
}
