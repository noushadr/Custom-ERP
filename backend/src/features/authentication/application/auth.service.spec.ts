import {
  BadRequestException,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { Permission } from '../domain/entities/permission.entity';
import { Role } from '../domain/entities/role.entity';
import { User } from '../domain/entities/user.entity';
import { UserStatus } from '../domain/enums/user-status.enum';
import type { UserRepository } from '../domain/repositories/user-repository.interface';
import { AuthService } from './auth.service';

jest.mock('bcryptjs');

function buildUser(overrides: Partial<User> = {}): User {
  const role = {
    id: 'role-1',
    name: 'Employee',
    permissions: [{ key: 'users.manage' } as Permission],
  } as Role;

  return {
    id: 'user-1',
    email: 'jane.doe@zeracreative.com',
    passwordHash: 'hashed-password',
    roleId: role.id,
    role,
    status: UserStatus.ACTIVE,
    lastLoginAt: undefined,
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  } as User;
}

describe('AuthService', () => {
  let service: AuthService;
  let userRepository: jest.Mocked<UserRepository>;
  let jwtService: jest.Mocked<JwtService>;
  let configService: jest.Mocked<ConfigService>;

  beforeEach(() => {
    userRepository = {
      findByEmail: jest.fn(),
      findById: jest.fn(),
      findAll: jest.fn(),
      save: jest.fn(),
    };

    jwtService = {
      sign: jest.fn().mockReturnValue('signed-token'),
      verify: jest.fn(),
    } as unknown as jest.Mocked<JwtService>;

    configService = {
      get: jest.fn().mockReturnValue('config-value'),
    } as unknown as jest.Mocked<ConfigService>;

    service = new AuthService(userRepository, jwtService, configService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('validateUser', () => {
    it('throws when no user exists for the email', async () => {
      userRepository.findByEmail.mockResolvedValue(null);

      await expect(
        service.validateUser('missing@zeracreative.com', 'password123'),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('throws when the user is disabled', async () => {
      userRepository.findByEmail.mockResolvedValue(
        buildUser({ status: UserStatus.DISABLED }),
      );

      await expect(
        service.validateUser('jane.doe@zeracreative.com', 'password123'),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('allows a pending-invite user to log in with the right password', async () => {
      userRepository.findByEmail.mockResolvedValue(
        buildUser({ status: UserStatus.PENDING_INVITE }),
      );
      (bcrypt.compare as jest.Mock).mockResolvedValue(true);

      await expect(
        service.validateUser('jane.doe@zeracreative.com', 'password123'),
      ).resolves.toBeDefined();
    });

    it('throws when the password does not match', async () => {
      userRepository.findByEmail.mockResolvedValue(buildUser());
      (bcrypt.compare as jest.Mock).mockResolvedValue(false);

      await expect(
        service.validateUser('jane.doe@zeracreative.com', 'wrong-password'),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('returns the user when credentials are valid', async () => {
      const user = buildUser();
      userRepository.findByEmail.mockResolvedValue(user);
      (bcrypt.compare as jest.Mock).mockResolvedValue(true);

      await expect(
        service.validateUser('jane.doe@zeracreative.com', 'password123'),
      ).resolves.toBe(user);
    });
  });

  describe('login', () => {
    it('records lastLoginAt and returns tokens with the authenticated user', async () => {
      const user = buildUser();
      userRepository.save.mockResolvedValue(user);

      const result = await service.login(user);

      expect(user.lastLoginAt).toBeInstanceOf(Date);
      expect(userRepository.save).toHaveBeenCalledWith(user);
      expect(result.accessToken).toBe('signed-token');
      expect(result.refreshToken).toBe('signed-token');
      expect(result.user).toEqual({
        id: user.id,
        email: user.email,
        role: user.role.name,
        permissions: ['users.manage'],
      });
    });
  });

  describe('refresh', () => {
    it('throws when the refresh token cannot be verified', async () => {
      jwtService.verify.mockImplementation(() => {
        throw new Error('invalid');
      });

      await expect(service.refresh('bad-token')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });

    it('throws when the token user no longer exists or is inactive', async () => {
      jwtService.verify.mockReturnValue({ sub: 'user-1' });
      userRepository.findById.mockResolvedValue(null);

      await expect(service.refresh('token')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });

    it('issues new tokens for a valid refresh token', async () => {
      const user = buildUser();
      jwtService.verify.mockReturnValue({ sub: user.id });
      userRepository.findById.mockResolvedValue(user);

      const result = await service.refresh('token');

      expect(result.accessToken).toBe('signed-token');
      expect(result.refreshToken).toBe('signed-token');
    });

    it('carries the impersonatedBy claim forward on refresh', async () => {
      const user = buildUser();
      jwtService.verify.mockReturnValue({
        sub: user.id,
        impersonatedBy: 'admin-1',
      });
      userRepository.findById.mockResolvedValue(user);

      await service.refresh('token');

      expect(jwtService.sign).toHaveBeenNthCalledWith(
        1,
        expect.objectContaining({ impersonatedBy: 'admin-1' }),
        expect.anything(),
      );
      expect(jwtService.sign).toHaveBeenNthCalledWith(
        2,
        expect.objectContaining({ impersonatedBy: 'admin-1' }),
        expect.anything(),
      );
    });
  });

  describe('impersonate', () => {
    it('throws when the target user does not exist', async () => {
      userRepository.findById.mockResolvedValue(null);

      await expect(
        service.impersonate('missing-user', 'admin-1'),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('throws when the target user is disabled', async () => {
      userRepository.findById.mockResolvedValue(
        buildUser({ status: UserStatus.DISABLED }),
      );

      await expect(
        service.impersonate('user-1', 'admin-1'),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('issues tokens for the target user tagged with the acting admin', async () => {
      const target = buildUser();
      userRepository.findById.mockResolvedValue(target);

      const result = await service.impersonate(target.id, 'admin-1');

      expect(result.accessToken).toBe('signed-token');
      expect(result.refreshToken).toBe('signed-token');
      expect(result.user).toEqual({
        id: target.id,
        email: target.email,
        role: target.role.name,
        permissions: ['users.manage'],
      });
      expect(jwtService.sign).toHaveBeenNthCalledWith(
        1,
        expect.objectContaining({ sub: target.id, impersonatedBy: 'admin-1' }),
        expect.anything(),
      );
      expect(jwtService.sign).toHaveBeenNthCalledWith(
        2,
        expect.objectContaining({ sub: target.id, impersonatedBy: 'admin-1' }),
        expect.anything(),
      );
    });

    it('logs who impersonated whom, for traceability', async () => {
      const admin = buildUser({ id: 'admin-1', email: 'admin@zeracreative.com' });
      const target = buildUser({ id: 'user-2', email: 'jane.doe@zeracreative.com' });
      userRepository.findById.mockImplementation(async (id) =>
        id === 'admin-1' ? admin : target,
      );
      const logSpy = jest.spyOn((service as unknown as { logger: { warn: () => void } }).logger, 'warn');

      await service.impersonate(target.id, admin.id);

      expect(logSpy).toHaveBeenCalledWith(
        expect.stringContaining('admin@zeracreative.com'),
      );
      expect(logSpy).toHaveBeenCalledWith(
        expect.stringContaining('jane.doe@zeracreative.com'),
      );
    });
  });

  describe('changePassword', () => {
    it('throws when the user does not exist', async () => {
      userRepository.findById.mockResolvedValue(null);

      await expect(
        service.changePassword('missing-user', 'old-password', 'new-password'),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('throws when the current password is wrong', async () => {
      userRepository.findById.mockResolvedValue(buildUser());
      (bcrypt.compare as jest.Mock).mockResolvedValue(false);

      await expect(
        service.changePassword('user-1', 'wrong-password', 'new-password'),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(userRepository.save).not.toHaveBeenCalled();
    });

    it('hashes and saves the new password when the current one matches', async () => {
      const user = buildUser();
      userRepository.findById.mockResolvedValue(user);
      (bcrypt.compare as jest.Mock).mockResolvedValue(true);
      (bcrypt.hash as jest.Mock).mockResolvedValue('new-hashed-password');

      await service.changePassword('user-1', 'old-password', 'new-password');

      expect(user.passwordHash).toBe('new-hashed-password');
      expect(userRepository.save).toHaveBeenCalledWith(user);
    });
  });
});
