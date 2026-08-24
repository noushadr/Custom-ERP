import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Lead } from '../../domain/entities/lead.entity';
import { LeadRepository } from '../../domain/repositories/lead-repository.interface';

@Injectable()
export class TypeOrmLeadRepository implements LeadRepository {
  constructor(
    @InjectRepository(Lead)
    private readonly repository: Repository<Lead>,
  ) {}

  findAll(): Promise<Lead[]> {
    return this.repository.find({
      order: { leadDate: 'DESC', createdAt: 'DESC' },
    });
  }

  findById(id: string): Promise<Lead | null> {
    return this.repository.findOne({ where: { id } });
  }

  save(lead: Lead): Promise<Lead> {
    return this.repository.save(lead);
  }
}
