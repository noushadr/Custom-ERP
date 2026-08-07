import { NotFoundException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Role } from '../domain/entities/role.entity';
import { User } from '../domain/entities/user.entity';
import { UserStatus } from '../domain/enums/user-status.enum';
import type { UserRepository } from '../domain/repositories/user-repository.interface';
import { UsersController } from './users.controller';

jest.mock('bcryptjs');

function buildUser(overrides: Partial<User> = {}): User {
  const role = { id: 'role-1', name: 'Employee' } as Role;
  return {
    id: 'user-1',
    email: 'jane.doe@zeracreative.com',
    passwordHash: 'old-hash',
    roleId: role.id,
    role,
    status: UserStatus.ACTIVE,
    lastLoginAt: undefined,
    ...overrides,
  } as User;
}

describe('UsersController', () => {
  let controller: UsersController;
  let userRepository: jest.Mocked<UserRepository>;

  beforeEach(() => {
    userRepository = {
      findByEmail: jest.fn(),
      findById: jest.fn(),
      findAll: jest.fn(),
      save: jest.fn(),
    };
    controller = new UsersController(userRepository);
    (bcrypt.hash as jest.Mock).mockResolvedValue('new-hash');
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('findAll', () => {
    it('maps users to their public shape', async () => {
      userRepository.findAll.mockResolvedValue([buildUser()]);

      const result = await controller.findAll();

      expect(result).toEqual([
        {
          id: 'user-1',
          email: 'jane.doe@zeracreative.com',
          role: 'Employee',
          status: UserStatus.ACTIVE,
          lastLoginAt: undefined,
        },
      ]);
    });
  });

  describe('resetPassword', () => {
    it('throws when the user does not exist', async () => {
      userRepository.findById.mockResolvedValue(null);

      await expect(controller.resetPassword('missing')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('hashes and saves a new temporary password, returning it once', async () => {
      const user = buildUser();
      userRepository.findById.mockResolvedValue(user);
      userRepository.save.mockResolvedValue(user);

      const result = await controller.resetPassword(user.id);

      expect(bcrypt.hash).toHaveBeenCalledWith(result.temporaryPassword, 10);
      expect(user.passwordHash).toBe('new-hash');
      expect(userRepository.save).toHaveBeenCalledWith(user);
      expect(result.temporaryPassword).toHaveLength(12);
    });
  });
});
