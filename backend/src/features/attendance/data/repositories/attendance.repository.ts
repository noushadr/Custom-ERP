import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Between, In, Repository } from 'typeorm';
import { randomUUID } from 'crypto';
import { AttendanceDeviceUser } from '../../domain/entities/attendance-device-user.entity';
import { AttendancePunch } from '../../domain/entities/attendance-punch.entity';
import { AttendanceSettings } from '../../domain/entities/attendance-settings.entity';
import { AttendanceRepository } from '../../domain/repositories/attendance-repository.interface';

const INSERT_CHUNK = 500;

@Injectable()
export class TypeOrmAttendanceRepository implements AttendanceRepository {
  constructor(
    @InjectRepository(AttendancePunch)
    private readonly punches: Repository<AttendancePunch>,
    @InjectRepository(AttendanceDeviceUser)
    private readonly deviceUsers: Repository<AttendanceDeviceUser>,
    @InjectRepository(AttendanceSettings)
    private readonly settings: Repository<AttendanceSettings>,
  ) {}

  async insertPunches(
    punches: { deviceUserId: string; punchedAt: Date }[],
  ): Promise<number> {
    let inserted = 0;
    for (let i = 0; i < punches.length; i += INSERT_CHUNK) {
      const chunk = punches.slice(i, i + INSERT_CHUNK);
      const result = await this.punches
        .createQueryBuilder()
        .insert()
        .into(AttendancePunch)
        .values(chunk.map((p) => ({ id: randomUUID(), ...p })))
        .orIgnore()
        .returning('id')
        .execute();
      inserted += result.raw?.length ?? 0;
    }
    return inserted;
  }

  findPunches(
    deviceUserIds: string[],
    from: Date,
    to: Date,
  ): Promise<AttendancePunch[]> {
    if (deviceUserIds.length === 0) return Promise.resolve([]);
    return this.punches.find({
      where: { deviceUserId: In(deviceUserIds), punchedAt: Between(from, to) },
      order: { punchedAt: 'ASC' },
    });
  }

  async replaceDeviceUsers(users: AttendanceDeviceUser[]): Promise<void> {
    await this.deviceUsers.save(users);
  }

  findDeviceUsers(): Promise<AttendanceDeviceUser[]> {
    return this.deviceUsers.find({ order: { name: 'ASC' } });
  }

  async setDeviceUserIgnored(
    deviceUserId: string,
    ignored: boolean,
  ): Promise<boolean> {
    const result = await this.deviceUsers.update({ deviceUserId }, { ignored });
    return (result.affected ?? 0) > 0;
  }

  async getSettings(): Promise<AttendanceSettings> {
    const existing = await this.settings.findOne({ where: { id: 1 } });
    if (existing) return existing;
    return this.settings.save(
      this.settings.create({
        id: 1,
        shiftStart: '11:00',
        shiftEnd: '19:00',
        graceMinutes: 15,
      }),
    );
  }

  saveSettings(settings: AttendanceSettings): Promise<AttendanceSettings> {
    return this.settings.save(settings);
  }
}
