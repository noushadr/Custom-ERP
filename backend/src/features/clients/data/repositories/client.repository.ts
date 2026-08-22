import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Client } from '../../domain/entities/client.entity';
import { ClientRepository } from '../../domain/repositories/client-repository.interface';

@Injectable()
export class TypeOrmClientRepository implements ClientRepository {
  constructor(
    @InjectRepository(Client)
    private readonly repository: Repository<Client>,
  ) {}

  findAll(includeArchived = false): Promise<Client[]> {
    return this.repository.find({
      where: includeArchived ? {} : { isArchived: false },
      order: { companyName: 'ASC' },
    });
  }

  findById(id: string): Promise<Client | null> {
    return this.repository.findOne({ where: { id } });
  }

  save(client: Client): Promise<Client> {
    return this.repository.save(client);
  }
}
