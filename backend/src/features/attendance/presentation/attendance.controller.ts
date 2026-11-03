import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  NotFoundException,
  Param,
  Post,
  Put,
  Query,
  Res,
} from '@nestjs/common';
import type { Response } from 'express';
import { CurrentUser } from '../../authentication/presentation/decorators/current-user.decorator';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import { generateAttendancePdf } from '../application/attendance-report.pdf';
import { AttendanceService } from '../application/attendance.service';
import {
  IgnoreDeviceUserDto,
  SetAttendanceMappingDto,
  UpdateAttendanceSettingsDto,
} from '../application/dto/attendance.dto';

/** Everyone can read their own attendance; everything company-wide, plus the
 * machine itself, needs `attendance.manage` (HR/Admin). */
@Controller('attendance')
export class AttendanceController {
  constructor(private readonly attendanceService: AttendanceService) {}

  @Get('me')
  getMine(
    @CurrentUser() user: JwtPayload,
    @Query('month') month: string,
    @Query('year') year: string,
  ) {
    return this.attendanceService.getMyMonth(
      user.sub,
      Number(month),
      Number(year),
    );
  }

  @Get('report')
  @Permissions('attendance.manage')
  getCompany(@Query('month') month: string, @Query('year') year: string) {
    return this.attendanceService.getCompanyMonth(
      Number(month),
      Number(year),
    );
  }

  /** PDF of one employee's month — your own, or anyone's for HR/Admin. With
   * no `employeeId`, HR/Admin get everyone in one file. */
  @Get('pdf')
  async downloadPdf(
    @CurrentUser() user: JwtPayload,
    @Query('month') month: string,
    @Query('year') year: string,
    @Res() res: Response,
    @Query('employeeId') employeeId?: string,
  ) {
    const canManage = user.permissions.includes('attendance.manage');
    const m = Number(month);
    const y = Number(year);

    let employees;
    if (employeeId) {
      if (!canManage) {
        const mine = await this.attendanceService.getMyMonth(user.sub, m, y);
        if (mine.employeeId !== employeeId) {
          throw new ForbiddenException('You can only export your own attendance');
        }
        employees = [mine];
      } else {
        employees = [
          await this.attendanceService.getEmployeeMonth(employeeId, m, y),
        ];
      }
    } else if (canManage) {
      employees = await this.attendanceService.getCompanyMonth(m, y);
    } else {
      employees = [await this.attendanceService.getMyMonth(user.sub, m, y)];
    }
    if (employees.length === 0) throw new NotFoundException('No data');

    const buffer = await generateAttendancePdf(employees, m, y);
    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename="attendance-${y}-${String(m).padStart(2, '0')}.pdf"`,
    });
    res.send(buffer);
  }

  @Get('settings')
  @Permissions('attendance.manage')
  getSettings() {
    return this.attendanceService.getSettings();
  }

  @Put('settings')
  @Permissions('attendance.manage')
  updateSettings(@Body() dto: UpdateAttendanceSettingsDto) {
    return this.attendanceService.updateSettings(dto);
  }

  @Post('sync')
  @Permissions('attendance.manage')
  sync() {
    return this.attendanceService.syncFromDevice();
  }

  @Get('mapping')
  @Permissions('attendance.manage')
  getMapping() {
    return this.attendanceService.getMapping();
  }

  @Put('mapping')
  @Permissions('attendance.manage')
  async setMapping(@Body() dto: SetAttendanceMappingDto) {
    await this.attendanceService.setMapping(dto.employeeId, dto.deviceUserId);
    return this.attendanceService.getMapping();
  }

  @Put('mapping/ignore')
  @Permissions('attendance.manage')
  async ignoreDeviceUser(@Body() dto: IgnoreDeviceUserDto) {
    await this.attendanceService.setDeviceUserIgnored(
      dto.deviceUserId,
      dto.ignored,
    );
    return this.attendanceService.getMapping();
  }

  @Post('mapping/auto')
  @Permissions('attendance.manage')
  autoMap() {
    return this.attendanceService.autoMap();
  }

  @Get('employees/:employeeId')
  @Permissions('attendance.manage')
  getEmployee(
    @Param('employeeId') employeeId: string,
    @Query('month') month: string,
    @Query('year') year: string,
  ) {
    return this.attendanceService.getEmployeeMonth(
      employeeId,
      Number(month),
      Number(year),
    );
  }
}
