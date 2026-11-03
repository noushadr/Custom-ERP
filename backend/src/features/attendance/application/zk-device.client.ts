import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
// zkteco-js ships no usable typings; the three calls used are declared below.
// eslint-disable-next-line @typescript-eslint/no-require-imports
const ZKLib = require('zkteco-js');

export interface DeviceUser {
  userId: string;
  name: string;
}

export interface DevicePunch {
  userId: string;
  time: Date;
}

export const ATTENDANCE_DEVICE = Symbol('ATTENDANCE_DEVICE');

/** The attendance machine, behind an interface so the sync logic is
 * testable without hardware. */
export interface AttendanceDevice {
  isConfigured(): boolean;
  /** Reads every enrolled user and every stored scan. Read-only: nothing is
   * ever cleared or changed on the machine. */
  readAll(): Promise<{ users: DeviceUser[]; punches: DevicePunch[] }>;
}

interface ZkSocket {
  createSocket(): Promise<void>;
  getUsers(): Promise<{ data: { userId: string; name: string }[] }>;
  getAttendances(): Promise<{
    data: { user_id: string; record_time: string | Date }[];
  }>;
  disconnect(): Promise<void>;
}

@Injectable()
export class ZkDeviceClient implements AttendanceDevice {
  constructor(private readonly config: ConfigService) {}

  isConfigured(): boolean {
    return !!this.config.get<string>('attendance.deviceHost');
  }

  async readAll(): Promise<{ users: DeviceUser[]; punches: DevicePunch[] }> {
    const host = this.config.get<string>('attendance.deviceHost');
    const port = this.config.get<number>('attendance.devicePort') ?? 4370;
    const timeout = this.config.get<number>('attendance.deviceTimeoutMs') ?? 10000;
    const zk: ZkSocket = new ZKLib(host, port, timeout, 4000);
    try {
      await zk.createSocket();
      const users = (await zk.getUsers()).data;
      const logs = (await zk.getAttendances()).data;
      return {
        users: users.map((u) => ({
          userId: String(u.userId),
          name: (u.name ?? '').trim(),
        })),
        punches: logs.map((l) => ({
          userId: String(l.user_id),
          time: new Date(l.record_time),
        })),
      };
    } finally {
      try {
        await zk.disconnect();
      } catch {
        // Already closed — nothing to clean up.
      }
    }
  }
}
