import { Freelancer } from '../entities/freelancer.entity';

export const FREELANCER_REPOSITORY = Symbol('FREELANCER_REPOSITORY');

export interface FreelancerRepository {
  findAll(activeOnly?: boolean): Promise<Freelancer[]>;
  findById(id: string): Promise<Freelancer | null>;
  save(freelancer: Freelancer): Promise<Freelancer>;
}
