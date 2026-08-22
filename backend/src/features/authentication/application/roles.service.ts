import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { definedFieldsOnly } from '../../../core/utils/defined-fields-only.util';
import { Permission } from '../domain/entities/permission.entity';
import { Role } from '../domain/entities/role.entity';
import { UserStatus } from '../domain/enums/user-status.enum';
import {
  PERMISSION_REPOSITORY,
  type PermissionRepository,
} from '../domain/repositories/permission-repository.interface';
import {
  ROLE_REPOSITORY,
  type RoleRepository,
} from '../domain/repositories/role-repository.interface';
import {
  USER_REPOSITORY,
  type UserRepository,
} from '../domain/repositories/user-repository.interface';
import { CreateRoleDto } from './dto/create-role.dto';
import { UpdateRoleDto } from './dto/update-role.dto';
import { PermissionResponse } from './permission-response.interface';
import { RoleResponse } from './role-response.interface';

@Injectable()
export class RolesService {
  constructor(
    @Inject(ROLE_REPOSITORY) private readonly roleRepository: RoleRepository,
    @Inject(PERMISSION_REPOSITORY)
    private readonly permissionRepository: PermissionRepository,
    @Inject(USER_REPOSITORY) private readonly userRepository: UserRepository,
  ) {}

  async listRoles(): Promise<RoleResponse[]> {
    const roles = await this.roleRepository.findAll();
    return Promise.all(
      roles.map(async (role) =>
        this.toResponse(role, await this.userCountByRoleId(role.id)),
      ),
    );
  }

  async listPermissions(): Promise<PermissionResponse[]> {
    const permissions = await this.permissionRepository.findAll();
    return permissions.map((permission) => ({
      key: permission.key,
      description: permission.description ?? null,
    }));
  }

  async createRole(dto: CreateRoleDto): Promise<RoleResponse> {
    const existing = await this.roleRepository.findByName(dto.name);
    if (existing) {
      throw new ConflictException('A role with this name already exists');
    }

    const permissions = await this.resolvePermissions(dto.permissionKeys);

    const role = new Role();
    role.name = dto.name;
    role.description = dto.description;
    role.isSystem = false;
    role.permissions = permissions;

    const saved = await this.roleRepository.save(role);
    return this.toResponse(saved, 0);
  }

  async updateRole(id: string, dto: UpdateRoleDto): Promise<RoleResponse> {
    const role = await this.roleRepository.findById(id);
    if (!role) throw new NotFoundException('Role not found');

    if (dto.name !== undefined && dto.name !== role.name) {
      if (role.isSystem) {
        throw new BadRequestException('System roles cannot be renamed');
      }

      const found = await this.roleRepository.findByName(dto.name);
      if (found && found.id !== id) {
        throw new ConflictException('A role with this name already exists');
      }
    }

    Object.assign(
      role,
      definedFieldsOnly({ name: dto.name, description: dto.description }),
    );

    if (dto.permissionKeys !== undefined) {
      role.permissions = await this.resolvePermissions(dto.permissionKeys);
    }

    const saved = await this.roleRepository.save(role);
    const userCount = await this.userCountByRoleId(saved.id);
    return this.toResponse(saved, userCount);
  }

  async deleteRole(id: string): Promise<void> {
    const role = await this.roleRepository.findById(id);
    if (!role) throw new NotFoundException('Role not found');

    if (role.isSystem) {
      throw new ConflictException('Default roles cannot be deleted');
    }

    const assigned = await this.userCountByRoleId(id);
    if (assigned > 0) {
      throw new ConflictException(
        `Cannot delete a role with ${assigned} employee(s) assigned. Reassign them first.`,
      );
    }

    await this.roleRepository.remove(role);
  }

  /** Active users whose role carries `permissionKey` — since Super Admin's
   * role is seeded with every known permission explicitly (see seed.ts),
   * this naturally includes Super Admin without any special-casing. Used
   * by the Automations module to resolve who should be notified by a
   * given automation (e.g. everyone holding `clients.manage`). */
  async findUsersWithPermission(
    permissionKey: string,
  ): Promise<{ id: string }[]> {
    const users = await this.userRepository.findAll();
    return users
      .filter(
        (user) =>
          user.status === UserStatus.ACTIVE &&
          user.role.permissions.some((p) => p.key === permissionKey),
      )
      .map((user) => ({ id: user.id }));
  }

  private async resolvePermissions(keys: string[]): Promise<Permission[]> {
    const permissions = await this.permissionRepository.findByKeys(keys);
    if (permissions.length !== new Set(keys).size) {
      throw new BadRequestException('One or more permission keys are invalid');
    }
    return permissions;
  }

  private async userCountByRoleId(roleId: string): Promise<number> {
    const users = await this.userRepository.findAll();
    return users.filter((u) => u.roleId === roleId).length;
  }

  private toResponse(role: Role, userCount: number): RoleResponse {
    return {
      id: role.id,
      name: role.name,
      description: role.description ?? null,
      isSystem: role.isSystem,
      permissions: role.permissions.map((p) => p.key),
      userCount,
    };
  }
}
