import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Team } from '../../domain/entities/team.entity';
import { TeamRepository } from '../../domain/repositories/team-repository.interface';

@Injectable()
export class TypeOrmTeamRepository implements TeamRepository {
  constructor(
    @InjectRepository(Team)
    private readonly repository: Repository<Team>,
  ) {}

  findAll(departmentId?: string, includeArchived = false): Promise<Team[]> {
    return this.repository.find({
      where: {
        ...(departmentId ? { departmentId } : {}),
        ...(includeArchived ? {} : { isArchived: false }),
      },
      order: { name: 'ASC' },
    });
  }

  findById(id: string): Promise<Team | null> {
    return this.repository.findOne({ where: { id } });
  }

  save(team: Team): Promise<Team> {
    return this.repository.save(team);
  }

  async remove(team: Team): Promise<void> {
    await this.repository.remove(team);
  }
}
