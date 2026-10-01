import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../domain/entities/user.entity';
import { UserRepository } from '../../domain/repositories/user-repository.interface';

@Injectable()
export class TypeOrmUserRepository implements UserRepository {
  constructor(
    @InjectRepository(User)
    private readonly repository: Repository<User>,
  ) {}

  // `role.permissions` is no longer eager (see role.entity.ts) — requested
  // explicitly here since login/refresh/impersonation and
  // `findUsersWithPermission` all need it.
  private static readonly RELATIONS = { role: { permissions: true } };

  findByEmail(email: string): Promise<User | null> {
    return this.repository.findOne({
      where: { email },
      relations: TypeOrmUserRepository.RELATIONS,
    });
  }

  findById(id: string): Promise<User | null> {
    return this.repository.findOne({
      where: { id },
      relations: TypeOrmUserRepository.RELATIONS,
    });
  }

  findAll(): Promise<User[]> {
    return this.repository.find({ relations: TypeOrmUserRepository.RELATIONS });
  }

  save(user: User): Promise<User> {
    return this.repository.save(user);
  }
}
