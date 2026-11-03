import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthenticationModule } from '../authentication/authentication.module';
import { EmployeeModule } from '../employee/employee.module';
import { HolidaysModule } from '../holidays/holidays.module';
import { LeaveModule } from '../leave/leave.module';
import { AttendanceService } from './application/attendance.service';
import { ATTENDANCE_DEVICE, ZkDeviceClient } from './application/zk-device.client';
import { TypeOrmAttendanceRepository } from './data/repositories/attendance.repository';
import { AttendanceDeviceUser } from './domain/entities/attendance-device-user.entity';
import { AttendancePunch } from './domain/entities/attendance-punch.entity';
import { AttendanceSettings } from './domain/entities/attendance-settings.entity';
import { ATTENDANCE_REPOSITORY } from './domain/repositories/attendance-repository.interface';
import { AttendanceController } from './presentation/attendance.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      AttendancePunch,
      AttendanceDeviceUser,
      AttendanceSettings,
    ]),
    AuthenticationModule,
    EmployeeModule,
    HolidaysModule,
    LeaveModule,
  ],
  controllers: [AttendanceController],
  providers: [
    AttendanceService,
    { provide: ATTENDANCE_REPOSITORY, useClass: TypeOrmAttendanceRepository },
    { provide: ATTENDANCE_DEVICE, useClass: ZkDeviceClient },
  ],
})
export class AttendanceModule {}
