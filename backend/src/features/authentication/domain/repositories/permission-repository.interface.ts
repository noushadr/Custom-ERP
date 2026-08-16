import { Permission } from '../entities/permission.entity';

export const PERMISSION_REPOSITORY = Symbol('PERMISSION_REPOSITORY');

export interface PermissionRepository {
  findAll(): Promise<Permission[]>;
  findByKeys(keys: string[]): Promise<Permission[]>;
}
