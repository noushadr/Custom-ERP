import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Asset } from '../../domain/entities/asset.entity';
import { AssetStatus } from '../../domain/enums/asset-status.enum';
import { AssetRepository } from '../../domain/repositories/asset-repository.interface';

@Injectable()
export class TypeOrmAssetRepository implements AssetRepository {
  constructor(
    @InjectRepository(Asset)
    private readonly repository: Repository<Asset>,
  ) {}

  findByAssignedEmployeeId(employeeId: string): Promise<Asset[]> {
    return this.repository.find({
      where: { assignedEmployeeId: employeeId },
      order: { assignedAt: 'DESC' },
    });
  }

  findAvailable(): Promise<Asset[]> {
    return this.repository.find({
      where: { status: AssetStatus.AVAILABLE },
      order: { name: 'ASC' },
    });
  }

  findById(id: string): Promise<Asset | null> {
    return this.repository.findOne({ where: { id } });
  }

  save(asset: Asset): Promise<Asset> {
    return this.repository.save(asset);
  }
}
