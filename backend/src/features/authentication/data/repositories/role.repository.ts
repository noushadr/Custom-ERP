import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Role } from '../../domain/entities/role.entity';
import { RoleRepository } from '../../domain/repositories/role-repository.interface';

@Injectable()
export class TypeOrmRoleRepository implements RoleRepository {
  constructor(
    @InjectRepository(Role)
    private readonly repository: Repository<Role>,
  ) {}

  // `permissions` is no longer eager (see role.entity.ts) — requested
  // explicitly here since every consumer of this repository (role
  // management, seed lookups, permission diffing) needs it.
  findByName(name: string): Promise<Role | null> {
    return this.repository.findOne({
      where: { name },
      relations: { permissions: true },
    });
  }

  findById(id: string): Promise<Role | null> {
    return this.repository.findOne({
      where: { id },
      relations: { permissions: true },
    });
  }

  findAll(): Promise<Role[]> {
    return this.repository.find({
      order: { name: 'ASC' },
      relations: { permissions: true },
    });
  }

  save(role: Role): Promise<Role> {
    return this.repository.save(role);
  }

  async remove(role: Role): Promise<void> {
    await this.repository.remove(role);
  }
}
