import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Project } from '../../domain/entities/project.entity';
import { ProjectRepository } from '../../domain/repositories/project-repository.interface';

@Injectable()
export class TypeOrmProjectRepository implements ProjectRepository {
  constructor(
    @InjectRepository(Project)
    private readonly repository: Repository<Project>,
  ) {}

  findAll(): Promise<Project[]> {
    return this.repository.find({ order: { createdAt: 'DESC' } });
  }

  findByClientId(clientId: string): Promise<Project[]> {
    return this.repository.find({
      where: { clientId },
      order: { createdAt: 'DESC' },
    });
  }

  findById(id: string): Promise<Project | null> {
    return this.repository.findOne({ where: { id } });
  }

  save(project: Project): Promise<Project> {
    return this.repository.save(project);
  }
}
