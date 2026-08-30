import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
import { CurrentUser } from '../../authentication/presentation/decorators/current-user.decorator';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import { CreateProfileChangeRequestDto } from '../application/dto/create-profile-change-request.dto';
import { CreateRequestDto } from '../application/dto/create-request.dto';
import { RejectRequestDto } from '../application/dto/reject-request.dto';
import { RequestsService } from '../application/requests.service';

@Controller('requests')
export class RequestsController {
  constructor(private readonly requestsService: RequestsService) {}

  @Post()
  submit(@Body() dto: CreateRequestDto, @CurrentUser() user: JwtPayload) {
    return this.requestsService.submit(user.sub, dto);
  }

  @Post('profile-changes')
  submitProfileChangeRequest(
    @Body() dto: CreateProfileChangeRequestDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.requestsService.submitProfileChangeRequest(user.sub, dto);
  }

  @Get('mine')
  findMine(@CurrentUser() user: JwtPayload) {
    return this.requestsService.findMine(user.sub);
  }

  @Get('pending-manager-approval')
  findPendingManagerApproval(@CurrentUser() user: JwtPayload) {
    return this.requestsService.findPendingManagerApproval(user.sub);
  }

  @Get('pending-hr-approval')
  @Permissions('users.manage')
  findPendingHrApproval() {
    return this.requestsService.findPendingHrApproval();
  }

  @Patch(':id/manager-approve')
  approveAsManager(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.requestsService.approveAsManager(id, user.sub);
  }

  @Patch(':id/manager-reject')
  rejectAsManager(
    @Param('id') id: string,
    @Body() dto: RejectRequestDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.requestsService.rejectAsManager(id, user.sub, dto.reason);
  }

  @Patch(':id/hr-approve')
  @Permissions('users.manage')
  approveAsHr(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.requestsService.approveAsHr(id, user.sub);
  }

  @Patch(':id/hr-reject')
  @Permissions('users.manage')
  rejectAsHr(
    @Param('id') id: string,
    @Body() dto: RejectRequestDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.requestsService.rejectAsHr(id, user.sub, dto.reason);
  }
}
