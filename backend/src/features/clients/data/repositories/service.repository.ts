import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Service } from '../../domain/entities/service.entity';
import { ServiceRepository } from '../../domain/repositories/service-repository.interface';

@Injectable()
export class TypeOrmServiceRepository implements ServiceRepository {
  constructor(
    @InjectRepository(Service)
    private readonly repository: Repository<Service>,
  ) {}

  findAll(includeArchived = false): Promise<Service[]> {
    return this.repository.find({
      where: includeArchived ? {} : { isArchived: false },
      order: { name: 'ASC' },
    });
  }

  findById(id: string): Promise<Service | null> {
    return this.repository.findOne({ where: { id } });
  }

  findByIds(ids: string[]): Promise<Service[]> {
    if (ids.length === 0) return Promise.resolve([]);
    return this.repository.find({ where: { id: In(ids) } });
  }

  save(service: Service): Promise<Service> {
    return this.repository.save(service);
  }
}
