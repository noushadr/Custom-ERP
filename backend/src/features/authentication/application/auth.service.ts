import {
  BadRequestException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import type { StringValue } from 'ms';
import { User } from '../domain/entities/user.entity';
import { UserStatus } from '../domain/enums/user-status.enum';
import {
  USER_REPOSITORY,
  type UserRepository,
} from '../domain/repositories/user-repository.interface';

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

export interface AuthenticatedUser {
  id: string;
  email: string;
  role: string;
  permissions: string[];
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @Inject(USER_REPOSITORY) private readonly userRepository: UserRepository,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async validateUser(email: string, password: string): Promise<User> {
    const user = await this.userRepository.findByEmail(email);
    // Pending-invite accounts may still log in with their temporary password;
    // only a disabled account is blocked outright.
    if (!user || user.status === UserStatus.DISABLED) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const passwordMatches = await bcrypt.compare(password, user.passwordHash);
    if (!passwordMatches) {
      throw new UnauthorizedException('Invalid credentials');
    }

    return user;
  }

  async login(user: User): Promise<AuthTokens & { user: AuthenticatedUser }> {
    user.lastLoginAt = new Date();
    await this.userRepository.save(user);

    return { ...this.issueTokens(user), user: this.toAuthenticatedUser(user) };
  }

  async refresh(refreshToken: string): Promise<AuthTokens> {
    let payload: { sub: string; impersonatedBy?: string };
    try {
      payload = this.jwtService.verify<{
        sub: string;
        impersonatedBy?: string;
      }>(refreshToken, {
        secret: this.configService.get<string>('jwt.refreshSecret'),
      });
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }

    const user = await this.userRepository.findById(payload.sub);
    if (!user || user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    return this.issueTokens(user, payload.impersonatedBy);
  }

  /** Issues a session for another user without their password. Restricted to
   * `users.impersonate` (Super Admin only, see seed.ts) at the controller. */
  async impersonate(
    targetUserId: string,
    actingAdminId: string,
  ): Promise<AuthTokens & { user: AuthenticatedUser }> {
    const target = await this.userRepository.findById(targetUserId);
    if (!target) throw new NotFoundException('User not found');
    if (target.status === UserStatus.DISABLED) {
      throw new BadRequestException('This account is disabled');
    }

    // No dedicated audit trail exists for impersonation yet — logging it
    // here is the minimum bar so who-acted-as-whom is at least traceable
    // in server logs, since the JWT's `impersonatedBy` claim alone isn't
    // queryable after the fact.
    const admin = await this.userRepository.findById(actingAdminId);
    this.logger.warn(
      `Impersonation started: ${admin?.email ?? actingAdminId} (${actingAdminId}) is now acting as ${target.email} (${target.id})`,
    );

    return {
      ...this.issueTokens(target, actingAdminId),
      user: this.toAuthenticatedUser(target),
    };
  }

  /** Self-service password change — requires knowing the current password,
   * unlike the HR-initiated reset in UsersController which does not. */
  async changePassword(
    userId: string,
    currentPassword: string,
    newPassword: string,
  ): Promise<void> {
    const user = await this.userRepository.findById(userId);
    if (!user) throw new NotFoundException('User not found');

    const passwordMatches = await bcrypt.compare(
      currentPassword,
      user.passwordHash,
    );
    if (!passwordMatches) {
      throw new BadRequestException('Current password is incorrect');
    }

    user.passwordHash = await bcrypt.hash(newPassword, 10);
    await this.userRepository.save(user);
  }

  toAuthenticatedUser(user: User): AuthenticatedUser {
    return {
      id: user.id,
      email: user.email,
      role: user.role.name,
      permissions: user.role.permissions?.map((p) => p.key) ?? [],
    };
  }

  private issueTokens(user: User, impersonatedBy?: string): AuthTokens {
    const payload = {
      sub: user.id,
      email: user.email,
      role: user.role.name,
      permissions: user.role.permissions?.map((p) => p.key) ?? [],
      ...(impersonatedBy ? { impersonatedBy } : {}),
    };

    const accessToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('jwt.secret'),
      expiresIn: this.configService.get<string>('jwt.expiresIn') as StringValue,
    });

    const refreshToken = this.jwtService.sign(
      { sub: user.id, ...(impersonatedBy ? { impersonatedBy } : {}) },
      {
        secret: this.configService.get<string>('jwt.refreshSecret'),
        expiresIn: this.configService.get<string>(
          'jwt.refreshExpiresIn',
        ) as StringValue,
      },
    );

    return { accessToken, refreshToken };
  }
}
