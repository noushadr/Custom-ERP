import { Team } from '../entities/team.entity';

export const TEAM_REPOSITORY = Symbol('TEAM_REPOSITORY');

export interface TeamRepository {
  findAll(departmentId?: string, includeArchived?: boolean): Promise<Team[]>;
  findById(id: string): Promise<Team | null>;
  save(team: Team): Promise<Team>;
  remove(team: Team): Promise<void>;
}
