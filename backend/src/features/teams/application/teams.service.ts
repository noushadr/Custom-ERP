import {
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { definedFieldsOnly } from '../../../core/utils/defined-fields-only.util';
import { Team } from '../domain/entities/team.entity';
import {
  TEAM_REPOSITORY,
  type TeamRepository,
} from '../domain/repositories/team-repository.interface';
import { CreateTeamDto } from './dto/create-team.dto';
import { UpdateTeamDto } from './dto/update-team.dto';

const FOREIGN_KEY_VIOLATION = '23503';

@Injectable()
export class TeamsService {
  constructor(
    @Inject(TEAM_REPOSITORY) private readonly teamRepository: TeamRepository,
  ) {}

  findAll(departmentId?: string, includeArchived = false): Promise<Team[]> {
    return this.teamRepository.findAll(departmentId, includeArchived);
  }

  create(dto: CreateTeamDto): Promise<Team> {
    const team = new Team();
    team.name = dto.name;
    team.departmentId = dto.departmentId;
    team.leadEmployeeId = dto.leadEmployeeId;
    return this.teamRepository.save(team);
  }

  async update(id: string, dto: UpdateTeamDto): Promise<Team> {
    const team = await this.teamRepository.findById(id);
    if (!team) throw new NotFoundException('Team not found');

    Object.assign(team, definedFieldsOnly(dto));
    return this.teamRepository.save(team);
  }

  async remove(id: string): Promise<void> {
    const team = await this.teamRepository.findById(id);
    if (!team) throw new NotFoundException('Team not found');

    try {
      await this.teamRepository.remove(team);
    } catch (error) {
      if (this.isForeignKeyViolation(error)) {
        throw new ConflictException(
          'Cannot delete a team that still has employees assigned. Archive ' +
            'it instead.',
        );
      }
      throw error;
    }
  }

  private isForeignKeyViolation(error: unknown): boolean {
    const code =
      (error as { code?: string })?.code ??
      (error as { driverError?: { code?: string } })?.driverError?.code;
    return code === FOREIGN_KEY_VIOLATION;
  }
}
