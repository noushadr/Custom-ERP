import { Lead } from '../entities/lead.entity';

export const LEAD_REPOSITORY = Symbol('LEAD_REPOSITORY');

export interface LeadRepository {
  findAll(): Promise<Lead[]>;
  findById(id: string): Promise<Lead | null>;
  save(lead: Lead): Promise<Lead>;
}
