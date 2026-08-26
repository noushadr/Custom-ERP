import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Freelancer } from '../../domain/entities/freelancer.entity';
import { FreelancerRepository } from '../../domain/repositories/freelancer-repository.interface';

@Injectable()
export class TypeOrmFreelancerRepository implements FreelancerRepository {
  constructor(
    @InjectRepository(Freelancer)
    private readonly repository: Repository<Freelancer>,
  ) {}

  findAll(activeOnly = false): Promise<Freelancer[]> {
    return this.repository.find({
      where: activeOnly ? { isActive: true } : {},
      order: { fullName: 'ASC' },
    });
  }

  findById(id: string): Promise<Freelancer | null> {
    return this.repository.findOne({ where: { id } });
  }

  save(freelancer: Freelancer): Promise<Freelancer> {
    return this.repository.save(freelancer);
  }
}
