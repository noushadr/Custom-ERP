import { Asset } from '../domain/entities/asset.entity';
import { AssetResponse } from './asset-response.interface';

export function toAssetResponse(asset: Asset): AssetResponse {
  return {
    id: asset.id,
    name: asset.name,
    category: asset.category ?? null,
    serialNumber: asset.serialNumber ?? null,
    status: asset.status,
    assignedEmployeeId: asset.assignedEmployeeId,
    assignedAt: asset.assignedAt,
    notes: asset.notes ?? null,
    createdAt: asset.createdAt,
  };
}
