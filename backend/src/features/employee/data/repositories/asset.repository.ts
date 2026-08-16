import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Asset } from '../../domain/entities/asset.entity';
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

  findById(id: string): Promise<Asset | null> {
    return this.repository.findOne({ where: { id } });
  }

  save(asset: Asset): Promise<Asset> {
    return this.repository.save(asset);
  }

  async remove(asset: Asset): Promise<void> {
    await this.repository.remove(asset);
  }
}
