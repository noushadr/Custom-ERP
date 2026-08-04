import { Team } from '../entities/team.entity';

export const TEAM_REPOSITORY = Symbol('TEAM_REPOSITORY');

export interface TeamRepository {
  findAll(departmentId?: string): Promise<Team[]>;
  findById(id: string): Promise<Team | null>;
  save(team: Team): Promise<Team>;
}
