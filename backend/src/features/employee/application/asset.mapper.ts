import { Asset } from '../domain/entities/asset.entity';
import { AssetResponse } from './asset-response.interface';

export function toAssetResponse(asset: Asset): AssetResponse {
  return {
    id: asset.id,
    name: asset.name,
    status: asset.status,
    assignedEmployeeId: asset.assignedEmployeeId,
    assignedAt: asset.assignedAt,
    value: asset.value ?? null,
    createdAt: asset.createdAt,
  };
}
