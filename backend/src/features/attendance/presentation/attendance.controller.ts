import {
  Body,
  Controller,
  Delete,
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
  AddWfhDayDto,
  IgnoreDeviceUserDto,
  SetWfhAttendanceDto,
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

  /** Any signed-in employee can refresh the data — it only reads the machine
   * and is skipped when a sync just happened. */
  @Post('refresh')
  refresh() {
    return this.attendanceService.refreshIfStale();
  }

  /** Company work-from-home days for the calendar — visible to everyone. */
  @Get('wfh-calendar')
  listWfhCalendar() {
    return this.attendanceService.listWfhCalendar();
  }

  @Get('wfh-days')
  @Permissions('attendance.manage')
  listWfhDays() {
    return this.attendanceService.listWfhDays();
  }

  @Post('wfh-days')
  @Permissions('attendance.manage')
  addWfhDay(@Body() dto: AddWfhDayDto) {
    return this.attendanceService.addWfhDay(dto);
  }

  @Delete('wfh-days/:date')
  @Permissions('attendance.manage')
  removeWfhDay(@Param('date') date: string) {
    return this.attendanceService.removeWfhDay(date);
  }

  @Get('wfh-days/:date/attendance')
  @Permissions('attendance.manage')
  getWfhDayAttendance(@Param('date') date: string) {
    return this.attendanceService.getWfhDayAttendance(date);
  }

  @Put('wfh-days/:date/attendance')
  @Permissions('attendance.manage')
  setWfhDayAttendance(
    @Param('date') date: string,
    @Body() dto: SetWfhAttendanceDto,
  ) {
    return this.attendanceService.setWfhDayAttendance(date, dto.employeeIds);
  }

  /** Mark one person's own day as work from home (no machine attendance). */
  @Post('employees/:employeeId/wfh-days')
  @Permissions('attendance.manage')
  async markEmployeeWfh(
    @Param('employeeId') employeeId: string,
    @Body() dto: AddWfhDayDto,
  ) {
    await this.attendanceService.markEmployeeWfh(employeeId, dto.date);
    return { employeeId, date: dto.date };
  }

  @Delete('employees/:employeeId/wfh-days/:date')
  @Permissions('attendance.manage')
  async unmarkEmployeeWfh(
    @Param('employeeId') employeeId: string,
    @Param('date') date: string,
  ) {
    await this.attendanceService.unmarkEmployeeWfh(employeeId, date);
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
