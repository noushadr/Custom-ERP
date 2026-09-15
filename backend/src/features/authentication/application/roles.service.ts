import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { definedFieldsOnly } from '../../../core/utils/defined-fields-only.util';
import { Permission } from '../domain/entities/permission.entity';
import { Role } from '../domain/entities/role.entity';
import { UserStatus } from '../domain/enums/user-status.enum';
import type { JwtPayload } from '../presentation/strategies/jwt.strategy';
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

/** The one role every other role's edits are checked against — see
 * `assertCanEditSuperAdminRole`. Matched by name rather than a dedicated
 * flag since it's the single seeded role that implicitly holds every
 * permission (see `seed.ts`); nothing else in this app singles out a role
 * by name, so this stays a narrowly-scoped exception, not a precedent for
 * hardcoding other role names elsewhere. */
const SUPER_ADMIN_ROLE_NAME = 'Super Admin';

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

  async createRole(
    dto: CreateRoleDto,
    caller: JwtPayload,
  ): Promise<RoleResponse> {
    const existing = await this.roleRepository.findByName(dto.name);
    if (existing) {
      throw new ConflictException('A role with this name already exists');
    }

    const permissions = await this.resolvePermissions(dto.permissionKeys);
    this.assertCallerHoldsPermissions(
      permissions.map((p) => p.key),
      caller,
    );

    const role = new Role();
    role.name = dto.name;
    role.description = dto.description;
    role.isSystem = false;
    role.permissions = permissions;

    const saved = await this.roleRepository.save(role);
    return this.toResponse(saved, 0);
  }

  async updateRole(
    id: string,
    dto: UpdateRoleDto,
    caller: JwtPayload,
  ): Promise<RoleResponse> {
    const role = await this.roleRepository.findById(id);
    if (!role) throw new NotFoundException('Role not found');

    if (role.name === SUPER_ADMIN_ROLE_NAME) {
      await this.assertCanEditSuperAdminRole(caller);
    }

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
      const permissions = await this.resolvePermissions(dto.permissionKeys);
      // Only the permissions genuinely being ADDED need to be held by the
      // caller — a permission the role already had (granted earlier by
      // someone else, e.g. a Super Admin) is fine to leave untouched even
      // if the current caller doesn't personally hold it themselves. Without
      // this distinction, a `roles.manage` holder like HR/Manager could
      // never save ANY edit (even just a description change) to a role that
      // happens to already carry a permission she doesn't hold.
      const currentKeys = new Set(role.permissions.map((p) => p.key));
      const newlyGrantedKeys = permissions
        .map((p) => p.key)
        .filter((key) => !currentKeys.has(key));
      this.assertCallerHoldsPermissions(newlyGrantedKeys, caller);
      role.permissions = permissions;
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
   * to resolve who should be notified about something (e.g. everyone
   * holding `leave.manage`). */
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

  /** Only a caller who already holds every known permission (i.e. is
   * functionally a Super Admin themselves, regardless of which role they're
   * actually assigned) may edit the Super Admin role — renaming it or
   * changing its permissions. This is what actually stops a non-Super-Admin
   * `roles.manage` holder (e.g. HR/Manager) from neutering the real admin
   * role, since nothing else about `roles.manage` distinguishes "the admin
   * role" from any other. */
  private async assertCanEditSuperAdminRole(caller: JwtPayload): Promise<void> {
    const allPermissions = await this.permissionRepository.findAll();
    const isUnrestricted = allPermissions.every((permission) =>
      caller.permissions.includes(permission.key),
    );
    if (!isUnrestricted) {
      throw new ForbiddenException(
        'Only a Super Admin can edit the Super Admin role',
      );
    }
  }

  /** A `roles.manage` holder can only grant a role permissions they
   * themselves already hold — otherwise HR/Manager (who now holds
   * `roles.manage` but not e.g. `finances.manage`/`leads.manage`/
   * `users.impersonate`) could hand any role, including her own, abilities
   * she doesn't have — a privilege-escalation path this permission was
   * never meant to open. */
  private assertCallerHoldsPermissions(
    keys: string[],
    caller: JwtPayload,
  ): void {
    const disallowed = keys.filter((key) => !caller.permissions.includes(key));
    if (disallowed.length > 0) {
      throw new ForbiddenException(
        `You cannot grant permissions you do not hold: ${disallowed.join(', ')}`,
      );
    }
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
