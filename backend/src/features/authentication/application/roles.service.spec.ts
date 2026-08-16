import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { Permission } from '../domain/entities/permission.entity';
import { Role } from '../domain/entities/role.entity';
import type { PermissionRepository } from '../domain/repositories/permission-repository.interface';
import type { RoleRepository } from '../domain/repositories/role-repository.interface';
import type { UserRepository } from '../domain/repositories/user-repository.interface';
import { User } from '../domain/entities/user.entity';
import { UserStatus } from '../domain/enums/user-status.enum';
import { UpdateRoleDto } from './dto/update-role.dto';
import { RolesService } from './roles.service';

function buildPermission(overrides: Partial<Permission> = {}): Permission {
  return {
    id: 'permission-1',
    key: 'employees.read',
    description: undefined,
    roles: [],
    ...overrides,
  } as Permission;
}

function buildRole(overrides: Partial<Role> = {}): Role {
  return {
    id: 'role-1',
    name: 'Team Lead',
    description: undefined,
    isSystem: false,
    permissions: [buildPermission()],
    users: [],
    ...overrides,
  } as Role;
}

function buildUser(overrides: Partial<User> = {}): User {
  return {
    id: 'user-1',
    email: 'jane.doe@zeracreative.com',
    passwordHash: 'hashed-password',
    roleId: 'role-1',
    status: UserStatus.ACTIVE,
    ...overrides,
  } as User;
}

describe('RolesService', () => {
  let service: RolesService;
  let roleRepository: jest.Mocked<RoleRepository>;
  let permissionRepository: jest.Mocked<PermissionRepository>;
  let userRepository: jest.Mocked<UserRepository>;

  beforeEach(() => {
    roleRepository = {
      findByName: jest.fn(),
      findById: jest.fn(),
      findAll: jest.fn(),
      save: jest.fn(),
      remove: jest.fn(),
    };

    permissionRepository = {
      findAll: jest.fn(),
      findByKeys: jest.fn(),
    };

    userRepository = {
      findByEmail: jest.fn(),
      findById: jest.fn(),
      findAll: jest.fn(),
      save: jest.fn(),
    };

    service = new RolesService(
      roleRepository,
      permissionRepository,
      userRepository,
    );
  });

  describe('listRoles', () => {
    it('maps role permissions to key strings and computes userCount from a mixed user list', async () => {
      const roleA = buildRole({
        id: 'role-1',
        name: 'Team Lead',
        permissions: [
          buildPermission({ key: 'employees.read' }),
          buildPermission({ key: 'teams.manage' }),
        ],
      });
      const roleB = buildRole({
        id: 'role-2',
        name: 'Employee',
        permissions: [],
      });
      roleRepository.findAll.mockResolvedValue([roleA, roleB]);
      userRepository.findAll.mockResolvedValue([
        buildUser({ id: 'user-1', roleId: 'role-1' }),
        buildUser({ id: 'user-2', roleId: 'role-1' }),
        buildUser({ id: 'user-3', roleId: 'role-2' }),
      ]);

      const result = await service.listRoles();

      expect(result).toEqual([
        {
          id: 'role-1',
          name: 'Team Lead',
          description: null,
          isSystem: false,
          permissions: ['employees.read', 'teams.manage'],
          userCount: 2,
        },
        {
          id: 'role-2',
          name: 'Employee',
          description: null,
          isSystem: false,
          permissions: [],
          userCount: 1,
        },
      ]);
    });
  });

  describe('listPermissions', () => {
    it('maps permissions to key/description pairs', async () => {
      permissionRepository.findAll.mockResolvedValue([
        buildPermission({ key: 'employees.read', description: 'Read employees' }),
        buildPermission({ key: 'roles.manage', description: undefined }),
      ]);

      const result = await service.listPermissions();

      expect(result).toEqual([
        { key: 'employees.read', description: 'Read employees' },
        { key: 'roles.manage', description: null },
      ]);
    });
  });

  describe('createRole', () => {
    it('succeeds with valid permission keys', async () => {
      roleRepository.findByName.mockResolvedValue(null);
      permissionRepository.findByKeys.mockResolvedValue([
        buildPermission({ key: 'employees.read' }),
      ]);
      roleRepository.save.mockImplementation((role) => Promise.resolve(role));

      const result = await service.createRole({
        name: 'Recruiter',
        description: 'Handles hiring',
        permissionKeys: ['employees.read'],
      });

      expect(result.name).toBe('Recruiter');
      expect(result.description).toBe('Handles hiring');
      expect(result.isSystem).toBe(false);
      expect(result.permissions).toEqual(['employees.read']);
      expect(result.userCount).toBe(0);
    });

    it('throws ConflictException on a duplicate name', async () => {
      roleRepository.findByName.mockResolvedValue(buildRole());

      await expect(
        service.createRole({
          name: 'Team Lead',
          permissionKeys: [],
        }),
      ).rejects.toBeInstanceOf(ConflictException);
      expect(roleRepository.save).not.toHaveBeenCalled();
    });

    it('throws BadRequestException on an unknown permission key', async () => {
      roleRepository.findByName.mockResolvedValue(null);
      permissionRepository.findByKeys.mockResolvedValue([]);

      await expect(
        service.createRole({
          name: 'Recruiter',
          permissionKeys: ['not.a.real.permission'],
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(roleRepository.save).not.toHaveBeenCalled();
    });
  });

  describe('updateRole', () => {
    it('renames a non-system role', async () => {
      const existing = buildRole({ name: 'Team Lead', isSystem: false });
      roleRepository.findById.mockResolvedValue(existing);
      roleRepository.findByName.mockResolvedValue(null);
      roleRepository.save.mockImplementation((role) => Promise.resolve(role));
      userRepository.findAll.mockResolvedValue([]);

      const result = await service.updateRole('role-1', {
        name: 'Senior Team Lead',
      });

      expect(result.name).toBe('Senior Team Lead');
    });

    it('throws BadRequestException attempting to rename an isSystem role', async () => {
      const existing = buildRole({ name: 'Employee', isSystem: true });
      roleRepository.findById.mockResolvedValue(existing);

      await expect(
        service.updateRole('role-1', { name: 'New Name' }),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(roleRepository.save).not.toHaveBeenCalled();
    });

    it('throws ConflictException renaming to a name already used by a different role', async () => {
      const existing = buildRole({
        id: 'role-1',
        name: 'Team Lead',
        isSystem: false,
      });
      roleRepository.findById.mockResolvedValue(existing);
      roleRepository.findByName.mockResolvedValue(
        buildRole({ id: 'role-2', name: 'Employee' }),
      );

      await expect(
        service.updateRole('role-1', { name: 'Employee' }),
      ).rejects.toBeInstanceOf(ConflictException);
      expect(roleRepository.save).not.toHaveBeenCalled();
    });

    it('updates permissionKeys alone without touching name/description — regression test for the real request shape', async () => {
      // The real HTTP pipeline runs the body through class-transformer, so a
      // partial update like `{ permissionKeys: [...] }` still yields an
      // UpdateRoleDto instance with every declared field present as an own
      // property (name/description explicitly `undefined`). definedFieldsOnly
      // must strip those before Object.assign, or they'd wipe name/description.
      const dto = plainToInstance(UpdateRoleDto, {
        permissionKeys: ['teams.manage'],
      });
      expect(Object.keys(dto)).toContain('name');
      expect(Object.keys(dto)).toContain('description');

      const existing = buildRole({
        name: 'Team Lead',
        description: 'Leads a team',
        isSystem: false,
        permissions: [buildPermission({ key: 'employees.read' })],
      });
      roleRepository.findById.mockResolvedValue(existing);
      permissionRepository.findByKeys.mockResolvedValue([
        buildPermission({ key: 'teams.manage' }),
      ]);
      roleRepository.save.mockImplementation((role) => Promise.resolve(role));
      userRepository.findAll.mockResolvedValue([]);

      const result = await service.updateRole('role-1', dto);

      expect(result.name).toBe('Team Lead');
      expect(result.description).toBe('Leads a team');
      expect(result.permissions).toEqual(['teams.manage']);
    });

    it('throws NotFoundException when the role does not exist', async () => {
      roleRepository.findById.mockResolvedValue(null);

      await expect(
        service.updateRole('missing-role', { name: 'New Name' }),
      ).rejects.toBeInstanceOf(NotFoundException);
      expect(roleRepository.save).not.toHaveBeenCalled();
    });
  });

  describe('deleteRole', () => {
    it('throws ConflictException for an isSystem role', async () => {
      roleRepository.findById.mockResolvedValue(buildRole({ isSystem: true }));

      await expect(service.deleteRole('role-1')).rejects.toBeInstanceOf(
        ConflictException,
      );
      expect(roleRepository.remove).not.toHaveBeenCalled();
    });

    it('throws ConflictException when users are still assigned', async () => {
      roleRepository.findById.mockResolvedValue(
        buildRole({ id: 'role-1', isSystem: false }),
      );
      userRepository.findAll.mockResolvedValue([
        buildUser({ roleId: 'role-1' }),
      ]);

      await expect(service.deleteRole('role-1')).rejects.toBeInstanceOf(
        ConflictException,
      );
      expect(roleRepository.remove).not.toHaveBeenCalled();
    });

    it('succeeds when the role is not system and has no assigned users', async () => {
      const existing = buildRole({ id: 'role-1', isSystem: false });
      roleRepository.findById.mockResolvedValue(existing);
      userRepository.findAll.mockResolvedValue([]);
      roleRepository.remove.mockResolvedValue(undefined);

      await service.deleteRole('role-1');

      expect(roleRepository.remove).toHaveBeenCalledWith(existing);
    });

    it('throws NotFoundException when the role does not exist', async () => {
      roleRepository.findById.mockResolvedValue(null);

      await expect(service.deleteRole('missing-role')).rejects.toBeInstanceOf(
        NotFoundException,
      );
      expect(roleRepository.remove).not.toHaveBeenCalled();
    });
  });
});
