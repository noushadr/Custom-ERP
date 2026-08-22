import {
  Controller,
  ForbiddenException,
  Get,
  HttpCode,
  HttpStatus,
  Inject,
  NotFoundException,
  Param,
  Post,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { generateTemporaryPassword } from '../../../core/utils/generate-temporary-password.util';
import {
  USER_REPOSITORY,
  type UserRepository,
} from '../domain/repositories/user-repository.interface';
import { CurrentUser } from './decorators/current-user.decorator';
import { Permissions } from './decorators/permissions.decorator';
import type { JwtPayload } from './strategies/jwt.strategy';

@Controller('users')
export class UsersController {
  constructor(
    @Inject(USER_REPOSITORY) private readonly userRepository: UserRepository,
  ) {}

  @Get()
  @Permissions('users.manage')
  async findAll() {
    const users = await this.userRepository.findAll();
    return users.map((user) => ({
      id: user.id,
      email: user.email,
      role: user.role.name,
      status: user.status,
      lastLoginAt: user.lastLoginAt,
    }));
  }

  /** Sets a new temporary password for any user, returned once so the
   * admin/HR can share it directly — there is no email delivery yet, same
   * as the invite flow.
   *
   * `users.manage` is held by HR/Manager as well as Super Admin, so without
   * the check below an HR/Manager could reset the Super Admin's own
   * password, read the temporary password back from this response, and log
   * in as Super Admin — a full privilege escalation that would defeat every
   * "Super Admin only" module in the app (Clients & Projects, Agency
   * Reporting, Finances, Payroll). Resetting a Super Admin's password is
   * therefore restricted to another Super Admin. */
  @Permissions('users.manage')
  @HttpCode(HttpStatus.OK)
  @Post(':id/reset-password')
  async resetPassword(
    @Param('id') id: string,
    @CurrentUser() actor: JwtPayload,
  ) {
    const user = await this.userRepository.findById(id);
    if (!user) throw new NotFoundException('User not found');

    if (user.role.name === 'Super Admin' && actor.role !== 'Super Admin') {
      throw new ForbiddenException(
        "Only a Super Admin can reset another Super Admin's password.",
      );
    }

    const temporaryPassword = generateTemporaryPassword();
    user.passwordHash = await bcrypt.hash(temporaryPassword, 10);
    await this.userRepository.save(user);

    return { temporaryPassword };
  }
}
