import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
} from '@nestjs/common';
import {
  AuthService,
  type AuthenticatedUser,
} from '../application/auth.service';
import { ChangePasswordDto } from '../application/dto/change-password.dto';
import { LoginDto } from '../application/dto/login.dto';
import { RefreshTokenDto } from '../application/dto/refresh-token.dto';
import { CurrentUser } from './decorators/current-user.decorator';
import { Permissions } from './decorators/permissions.decorator';
import { Public } from './decorators/public.decorator';
import type { JwtPayload } from './strategies/jwt.strategy';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @HttpCode(HttpStatus.OK)
  @Post('login')
  async login(@Body() dto: LoginDto) {
    const user = await this.authService.validateUser(dto.email, dto.password);
    return this.authService.login(user);
  }

  @Public()
  @HttpCode(HttpStatus.OK)
  @Post('refresh')
  refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refresh(dto.refreshToken);
  }

  @Get('me')
  me(@CurrentUser() user: JwtPayload): AuthenticatedUser {
    return {
      id: user.sub,
      email: user.email,
      role: user.role,
      permissions: user.permissions,
    };
  }

  @Permissions('users.impersonate')
  @HttpCode(HttpStatus.OK)
  @Post('impersonate/:userId')
  impersonate(
    @Param('userId') userId: string,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.authService.impersonate(userId, user.sub);
  }

  @HttpCode(HttpStatus.OK)
  @Post('change-password')
  changePassword(
    @Body() dto: ChangePasswordDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.authService.changePassword(
      user.sub,
      dto.currentPassword,
      dto.newPassword,
    );
  }
}
