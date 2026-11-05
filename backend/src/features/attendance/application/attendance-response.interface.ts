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
  hoursCutAfter: string;
  hoursCutFrom: string;
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

/** One work-from-home day a viewer should be told about. */
export interface WfhNoticeResponse {
  /** True when only this person was marked (not a company-wide day). */
  personal: boolean;
  note: string | null;
}

export interface WfhAnnouncementResponse {
  today: WfhNoticeResponse | null;
  tomorrow: WfhNoticeResponse | null;
}

export interface WfhDayResponse {
  date: string;
  note: string | null;
  /** How many tracked employees HR has marked as worked that day. */
  presentCount: number;
}

export interface WfhDayEmployeeResponse {
  employeeId: string;
  employeeName: string;
  employeeCode: string;
  present: boolean;
}

export interface SyncResultResponse {
  fetched: number;
  inserted: number;
  users: number;
  /** True when a recent sync made a new one unnecessary. */
  skipped?: boolean;
}
