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

  findByName(name: string): Promise<Role | null> {
    return this.repository.findOne({ where: { name } });
  }
}
