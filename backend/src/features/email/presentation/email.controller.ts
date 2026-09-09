import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Put,
  Query,
} from '@nestjs/common';
import { CurrentUser } from '../../authentication/presentation/decorators/current-user.decorator';
import { Permissions } from '../../authentication/presentation/decorators/permissions.decorator';
import type { JwtPayload } from '../../authentication/presentation/strategies/jwt.strategy';
import { SendEmailDto } from '../application/dto/send-email.dto';
import { SetupEmailAccountDto } from '../application/dto/setup-email-account.dto';
import { EmailService } from '../application/email.service';

@Controller('email')
export class EmailController {
  constructor(private readonly emailService: EmailService) {}

  @Get('account/me')
  getMyAccount(@CurrentUser() user: JwtPayload) {
    return this.emailService.getMyAccount(user.sub);
  }

  @Put('account/me')
  setupMyAccount(
    @Body() dto: SetupEmailAccountDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.emailService.setupMyAccount(user.sub, dto);
  }

  @Delete('account/me')
  removeMyAccount(@CurrentUser() user: JwtPayload) {
    return this.emailService.removeMyAccount(user.sub);
  }

  @Get('account/:employeeId')
  @Permissions('email.manage')
  getAccountForEmployee(@Param('employeeId') employeeId: string) {
    return this.emailService.getAccountForEmployee(employeeId);
  }

  @Put('account/:employeeId')
  @Permissions('email.manage')
  setupForEmployee(
    @Param('employeeId') employeeId: string,
    @Body() dto: SetupEmailAccountDto,
  ) {
    return this.emailService.setupForEmployee(employeeId, dto);
  }

  @Delete('account/:employeeId')
  @Permissions('email.manage')
  removeForEmployee(@Param('employeeId') employeeId: string) {
    return this.emailService.removeForEmployee(employeeId);
  }

  @Post('send')
  sendMail(@Body() dto: SendEmailDto, @CurrentUser() user: JwtPayload) {
    return this.emailService.sendMail(user.sub, dto);
  }

  @Get('inbox')
  listInbox(
    @CurrentUser() user: JwtPayload,
    @Query('limit', new ParseIntPipe({ optional: true })) limit?: number,
  ) {
    return this.emailService.listInbox(user.sub, limit ?? 25);
  }

  @Get('inbox/:uid')
  getMessage(
    @Param('uid', ParseIntPipe) uid: number,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.emailService.getMessage(user.sub, uid);
  }
}
