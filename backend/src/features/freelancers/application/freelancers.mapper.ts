import { Freelancer } from '../domain/entities/freelancer.entity';
import { FreelancerResponseDto } from './freelancer-response.interface';

export function toFreelancerResponse(
  freelancer: Freelancer,
): FreelancerResponseDto {
  return {
    id: freelancer.id,
    fullName: freelancer.fullName,
    role: freelancer.role ?? null,
    notes: freelancer.notes ?? null,
    isActive: freelancer.isActive,
    createdAt: freelancer.createdAt.toISOString(),
    updatedAt: freelancer.updatedAt.toISOString(),
  };
}
