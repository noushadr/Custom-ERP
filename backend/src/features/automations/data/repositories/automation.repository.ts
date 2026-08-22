import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Automation } from '../../domain/entities/automation.entity';
import { AutomationType } from '../../domain/enums/automation-type.enum';
import { AutomationRepository } from '../../domain/repositories/automation-repository.interface';

@Injectable()
export class TypeOrmAutomationRepository implements AutomationRepository {
  constructor(
    @InjectRepository(Automation)
    private readonly repository: Repository<Automation>,
  ) {}

  findAll(): Promise<Automation[]> {
    return this.repository.find();
  }

  findByType(type: AutomationType): Promise<Automation | null> {
    return this.repository.findOne({ where: { type } });
  }

  save(automation: Automation): Promise<Automation> {
    return this.repository.save(automation);
  }
}
