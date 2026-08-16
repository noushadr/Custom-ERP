import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { TypeOrmModule } from '@nestjs/typeorm';
import type { StringValue } from 'ms';
import { AuthService } from './application/auth.service';
import { RolesService } from './application/roles.service';
import { TypeOrmPermissionRepository } from './data/repositories/permission.repository';
import { TypeOrmRoleRepository } from './data/repositories/role.repository';
import { TypeOrmUserRepository } from './data/repositories/user.repository';
import { Permission } from './domain/entities/permission.entity';
import { Role } from './domain/entities/role.entity';
import { User } from './domain/entities/user.entity';
import { PERMISSION_REPOSITORY } from './domain/repositories/permission-repository.interface';
import { ROLE_REPOSITORY } from './domain/repositories/role-repository.interface';
import { USER_REPOSITORY } from './domain/repositories/user-repository.interface';
import { AuthController } from './presentation/auth.controller';
import { JwtAuthGuard } from './presentation/guards/jwt-auth.guard';
import { PermissionsGuard } from './presentation/guards/permissions.guard';
import { PermissionsController } from './presentation/permissions.controller';
import { RolesController } from './presentation/roles.controller';
import { JwtStrategy } from './presentation/strategies/jwt.strategy';
import { UsersController } from './presentation/users.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, Role, Permission]),
    PassportModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('jwt.secret'),
        signOptions: {
          expiresIn: config.get<string>('jwt.expiresIn') as StringValue,
        },
      }),
    }),
  ],
  controllers: [
    AuthController,
    UsersController,
    RolesController,
    PermissionsController,
  ],
  providers: [
    AuthService,
    RolesService,
    JwtStrategy,
    { provide: USER_REPOSITORY, useClass: TypeOrmUserRepository },
    { provide: ROLE_REPOSITORY, useClass: TypeOrmRoleRepository },
    { provide: PERMISSION_REPOSITORY, useClass: TypeOrmPermissionRepository },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: PermissionsGuard },
  ],
  exports: [USER_REPOSITORY, ROLE_REPOSITORY, RolesService],
})
export class AuthenticationModule {}
