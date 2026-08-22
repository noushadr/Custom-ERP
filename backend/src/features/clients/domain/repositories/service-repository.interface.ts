import { Service } from '../entities/service.entity';

export const SERVICE_REPOSITORY = Symbol('SERVICE_REPOSITORY');

export interface ServiceRepository {
  findAll(includeArchived?: boolean): Promise<Service[]>;
  findById(id: string): Promise<Service | null>;
  findByIds(ids: string[]): Promise<Service[]>;
  save(service: Service): Promise<Service>;
}
