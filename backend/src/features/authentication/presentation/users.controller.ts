import {
  Controller,
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
import { Permissions } from './decorators/permissions.decorator';

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
   * as the invite flow. */
  @Permissions('users.manage')
  @HttpCode(HttpStatus.OK)
  @Post(':id/reset-password')
  async resetPassword(@Param('id') id: string) {
    const user = await this.userRepository.findById(id);
    if (!user) throw new NotFoundException('User not found');

    const temporaryPassword = generateTemporaryPassword();
    user.passwordHash = await bcrypt.hash(temporaryPassword, 10);
    await this.userRepository.save(user);

    return { temporaryPassword };
  }
}
