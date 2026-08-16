import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Permission } from '../../domain/entities/permission.entity';
import { PermissionRepository } from '../../domain/repositories/permission-repository.interface';

@Injectable()
export class TypeOrmPermissionRepository implements PermissionRepository {
  constructor(
    @InjectRepository(Permission)
    private readonly repository: Repository<Permission>,
  ) {}

  findAll(): Promise<Permission[]> {
    return this.repository.find({ order: { key: 'ASC' } });
  }

  findByKeys(keys: string[]): Promise<Permission[]> {
    return this.repository.find({ where: { key: In(keys) } });
  }
}
