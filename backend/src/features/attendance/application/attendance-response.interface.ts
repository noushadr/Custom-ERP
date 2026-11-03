import { AttendanceDay, AttendanceSummary } from './attendance.calculator';

export interface EmployeeAttendanceResponse {
  employeeId: string;
  employeeName: string;
  employeeCode: string;
  profilePhotoUrl: string | null;
  /** False when the employee isn't linked to a machine user yet. */
  linked: boolean;
  /** Remote staff aren't tracked on the machine at all. */
  remote: boolean;
  days: AttendanceDay[];
  summary: AttendanceSummary;
}

export interface AttendanceSettingsResponse {
  shiftStart: string;
  shiftEnd: string;
  graceMinutes: number;
  lastSyncAt: string | null;
  lastSyncMessage: string | null;
  deviceConfigured: boolean;
}

export interface AttendanceMappingResponse {
  deviceUserId: string;
  deviceName: string;
  employeeId: string | null;
  employeeName: string | null;
  ignored: boolean;
}

export interface SyncResultResponse {
  fetched: number;
  inserted: number;
  users: number;
}
