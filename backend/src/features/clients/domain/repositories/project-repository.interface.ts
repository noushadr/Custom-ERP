import { Project } from '../entities/project.entity';

export const PROJECT_REPOSITORY = Symbol('PROJECT_REPOSITORY');

export interface ProjectRepository {
  findAll(): Promise<Project[]>;
  findByClientId(clientId: string): Promise<Project[]>;
  findById(id: string): Promise<Project | null>;
  save(project: Project): Promise<Project>;
}
