import { Client } from '../entities/client.entity';

export const CLIENT_REPOSITORY = Symbol('CLIENT_REPOSITORY');

export interface ClientRepository {
  findAll(includeArchived?: boolean): Promise<Client[]>;
  findById(id: string): Promise<Client | null>;
  save(client: Client): Promise<Client>;
}
