import { Asset } from '../entities/asset.entity';

export const ASSET_REPOSITORY = Symbol('ASSET_REPOSITORY');

export interface AssetRepository {
  findByAssignedEmployeeId(employeeId: string): Promise<Asset[]>;
  /** Currently unassigned assets — used to populate the "assign existing
   * asset" picker. */
  findAvailable(): Promise<Asset[]>;
  findById(id: string): Promise<Asset | null>;
  save(asset: Asset): Promise<Asset>;
}
