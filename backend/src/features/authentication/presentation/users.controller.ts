import { Controller, Get, Inject } from '@nestjs/common';
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
}
