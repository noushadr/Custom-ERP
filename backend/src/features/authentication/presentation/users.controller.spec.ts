import { ForbiddenException, NotFoundException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Role } from '../domain/entities/role.entity';
import { User } from '../domain/entities/user.entity';
import { UserStatus } from '../domain/enums/user-status.enum';
import type { UserRepository } from '../domain/repositories/user-repository.interface';
import type { JwtPayload } from './strategies/jwt.strategy';
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

function buildActor(overrides: Partial<JwtPayload> = {}): JwtPayload {
  return {
    sub: 'actor-1',
    email: 'admin@zeracreative.com',
    role: 'Super Admin',
    permissions: ['users.manage'],
    ...overrides,
  };
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

      await expect(
        controller.resetPassword('missing', buildActor()),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('hashes and saves a new temporary password, returning it once', async () => {
      const user = buildUser();
      userRepository.findById.mockResolvedValue(user);
      userRepository.save.mockResolvedValue(user);

      const result = await controller.resetPassword(user.id, buildActor());

      expect(bcrypt.hash).toHaveBeenCalledWith(result.temporaryPassword, 10);
      expect(user.passwordHash).toBe('new-hash');
      expect(userRepository.save).toHaveBeenCalledWith(user);
      expect(result.temporaryPassword).toHaveLength(12);
    });

    it("blocks an HR/Manager from resetting a Super Admin's password — regression: this endpoint previously had no role-hierarchy check at all, letting a users.manage holder (HR/Manager, not just Super Admin) reset the Super Admin's password, read the temporary password from the response, and log in as Super Admin", async () => {
      const superAdminTarget = buildUser({
        id: 'super-admin-1',
        role: { id: 'role-super-admin', name: 'Super Admin' } as Role,
      });
      userRepository.findById.mockResolvedValue(superAdminTarget);

      await expect(
        controller.resetPassword(
          superAdminTarget.id,
          buildActor({ role: 'HR/Manager' }),
        ),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(userRepository.save).not.toHaveBeenCalled();
    });

    it("allows a Super Admin to reset another Super Admin's password", async () => {
      const superAdminTarget = buildUser({
        id: 'super-admin-2',
        role: { id: 'role-super-admin', name: 'Super Admin' } as Role,
      });
      userRepository.findById.mockResolvedValue(superAdminTarget);
      userRepository.save.mockResolvedValue(superAdminTarget);

      const result = await controller.resetPassword(
        superAdminTarget.id,
        buildActor({ role: 'Super Admin' }),
      );

      expect(result.temporaryPassword).toHaveLength(12);
      expect(userRepository.save).toHaveBeenCalledWith(superAdminTarget);
    });

    it('still allows an HR/Manager to reset a regular employee\'s password', async () => {
      const employeeTarget = buildUser();
      userRepository.findById.mockResolvedValue(employeeTarget);
      userRepository.save.mockResolvedValue(employeeTarget);

      const result = await controller.resetPassword(
        employeeTarget.id,
        buildActor({ role: 'HR/Manager' }),
      );

      expect(result.temporaryPassword).toHaveLength(12);
    });
  });
});
