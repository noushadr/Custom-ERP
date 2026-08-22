import { ClientHealthHistory } from '../entities/client-health-history.entity';

export const CLIENT_HEALTH_HISTORY_REPOSITORY = Symbol(
  'CLIENT_HEALTH_HISTORY_REPOSITORY',
);

export interface ClientHealthHistoryRepository {
  findByClientId(clientId: string): Promise<ClientHealthHistory[]>;
  save(entry: ClientHealthHistory): Promise<ClientHealthHistory>;
}
