import { Inject, Injectable } from '@nestjs/common';
import { Team } from '../domain/entities/team.entity';
import {
  TEAM_REPOSITORY,
  type TeamRepository,
} from '../domain/repositories/team-repository.interface';
import { CreateTeamDto } from './dto/create-team.dto';

@Injectable()
export class TeamsService {
  constructor(
    @Inject(TEAM_REPOSITORY) private readonly teamRepository: TeamRepository,
  ) {}

  findAll(departmentId?: string): Promise<Team[]> {
    return this.teamRepository.findAll(departmentId);
  }

  create(dto: CreateTeamDto): Promise<Team> {
    const team = new Team();
    team.name = dto.name;
    team.departmentId = dto.departmentId;
    team.leadEmployeeId = dto.leadEmployeeId;
    return this.teamRepository.save(team);
  }
}
