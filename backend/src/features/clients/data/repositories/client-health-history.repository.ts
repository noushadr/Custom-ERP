import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ClientHealthHistory } from '../../domain/entities/client-health-history.entity';
import { ClientHealthHistoryRepository } from '../../domain/repositories/client-health-history-repository.interface';

@Injectable()
export class TypeOrmClientHealthHistoryRepository
  implements ClientHealthHistoryRepository
{
  constructor(
    @InjectRepository(ClientHealthHistory)
    private readonly repository: Repository<ClientHealthHistory>,
  ) {}

  findByClientId(clientId: string): Promise<ClientHealthHistory[]> {
    return this.repository.find({
      where: { clientId },
      order: { createdAt: 'DESC' },
    });
  }

  save(entry: ClientHealthHistory): Promise<ClientHealthHistory> {
    return this.repository.save(entry);
  }
}
