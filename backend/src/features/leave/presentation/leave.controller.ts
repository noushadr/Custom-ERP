import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { CurrentUser } from '../../authentication/presentation/decorators/current-user.decorator';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import { AdjustLeaveBalanceDto } from '../application/dto/adjust-leave-balance.dto';
import { CreateLeaveTypeDto } from '../application/dto/create-leave-type.dto';
import { DecideLeaveRequestDto } from '../application/dto/decide-leave-request.dto';
import { SubmitLeaveRequestDto } from '../application/dto/submit-leave-request.dto';
import { UpdateLeaveTypeDto } from '../application/dto/update-leave-type.dto';
import { LeaveService } from '../application/leave.service';

@Controller('leave')
export class LeaveController {
  constructor(private readonly leaveService: LeaveService) {}

  @Get('types')
  getLeaveTypes(@Query('includeArchived') includeArchived?: string) {
    return this.leaveService.getLeaveTypes(includeArchived === 'true');
  }

  @Post('types')
  @Permissions('leave.manage')
  createLeaveType(@Body() dto: CreateLeaveTypeDto) {
    return this.leaveService.createLeaveType(dto);
  }

  @Patch('types/:id')
  @Permissions('leave.manage')
  updateLeaveType(@Param('id') id: string, @Body() dto: UpdateLeaveTypeDto) {
    return this.leaveService.updateLeaveType(id, dto);
  }

  @Delete('types/:id')
  @Permissions('leave.manage')
  @HttpCode(204)
  removeLeaveType(@Param('id') id: string) {
    return this.leaveService.removeLeaveType(id);
  }

  @Post('requests')
  submitLeaveRequest(
    @Body() dto: SubmitLeaveRequestDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.leaveService.submitLeaveRequest(user.sub, dto);
  }

  @Get('requests/mine')
  getMyLeaveRequests(@CurrentUser() user: JwtPayload) {
    return this.leaveService.getMyLeaveRequests(user.sub);
  }

  @Get('requests/pending-manager-approval')
  getPendingManagerApproval(@CurrentUser() user: JwtPayload) {
    return this.leaveService.getPendingManagerApproval(user.sub);
  }

  @Get('requests/pending-hr-approval')
  @Permissions('leave.manage')
  getPendingHrApproval() {
    return this.leaveService.getPendingHrApproval();
  }

  @Patch('requests/:id/cancel')
  cancelLeaveRequest(
    @Param('id') id: string,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.leaveService.cancelLeaveRequest(user.sub, id);
  }

  @Patch('requests/:id/manager-approve')
  approveAsManager(
    @Param('id') id: string,
    @Body() dto: DecideLeaveRequestDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.leaveService.approveAsManager(id, user.sub, dto.comment);
  }

  @Patch('requests/:id/manager-reject')
  rejectAsManager(
    @Param('id') id: string,
    @Body() dto: DecideLeaveRequestDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.leaveService.rejectAsManager(id, user.sub, dto.comment);
  }

  @Patch('requests/:id/hr-approve')
  @Permissions('leave.manage')
  approveAsHr(
    @Param('id') id: string,
    @Body() dto: DecideLeaveRequestDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.leaveService.approveAsHr(id, user.sub, dto.comment);
  }

  @Patch('requests/:id/hr-reject')
  @Permissions('leave.manage')
  rejectAsHr(
    @Param('id') id: string,
    @Body() dto: DecideLeaveRequestDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.leaveService.rejectAsHr(id, user.sub, dto.comment);
  }

  @Get('balances/mine')
  getMyBalances(@CurrentUser() user: JwtPayload) {
    return this.leaveService.getMyBalances(user.sub);
  }

  @Get('balances/mine/history')
  getMyBalanceHistory(@CurrentUser() user: JwtPayload) {
    return this.leaveService.getMyBalanceHistory(user.sub);
  }

  @Get('reset-status')
  @Permissions('leave.manage')
  getResetStatus() {
    return this.leaveService.getResetStatus();
  }

  @Post('reset')
  @Permissions('leave.manage')
  runAnnualReset() {
    return this.leaveService.runAnnualReset();
  }

  @Get('calendar')
  getLeaveCalendar(
    @CurrentUser() user: JwtPayload,
    @Query('month') month: string,
    @Query('year') year: string,
    @Query('scope') scope?: 'team' | 'company',
  ) {
    return this.leaveService.getLeaveCalendar(
      user.sub,
      scope === 'company' ? 'company' : 'team',
      Number(month),
      Number(year),
      user.permissions.includes('leave.manage'),
    );
  }

  // Must come after "mine"/"mine/history" above — otherwise those literal
  // segments would be captured as the :employeeId param instead.
  @Get('balances/:employeeId')
  @Permissions('leave.manage')
  getEmployeeBalances(@Param('employeeId') employeeId: string) {
    return this.leaveService.getEmployeeBalances(employeeId);
  }

  @Post('balances/:employeeId/adjust')
  @Permissions('leave.manage')
  adjustBalance(
    @Param('employeeId') employeeId: string,
    @Body() dto: AdjustLeaveBalanceDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.leaveService.adjustBalance(employeeId, dto, user.sub);
  }
}
