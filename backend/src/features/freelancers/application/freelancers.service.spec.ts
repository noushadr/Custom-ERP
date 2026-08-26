import { NotFoundException } from '@nestjs/common';
import { Freelancer } from '../domain/entities/freelancer.entity';
import type { FreelancerRepository } from '../domain/repositories/freelancer-repository.interface';
import { FreelancersService } from './freelancers.service';

function buildFreelancer(overrides: Partial<Freelancer> = {}): Freelancer {
  return {
    id: 'freelancer-1',
    fullName: 'Kulsum Zehra',
    role: 'Content Writer',
    notes: null,
    isActive: true,
    createdAt: new Date('2026-08-01T00:00:00.000Z'),
    updatedAt: new Date('2026-08-01T00:00:00.000Z'),
    ...overrides,
  } as Freelancer;
}

describe('FreelancersService', () => {
  let service: FreelancersService;
  let repository: jest.Mocked<FreelancerRepository>;

  beforeEach(() => {
    repository = {
      findAll: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      save: jest.fn((freelancer) =>
        Promise.resolve({
          ...freelancer,
          id: freelancer.id ?? 'freelancer-1',
          createdAt: freelancer.createdAt ?? new Date('2026-08-01T00:00:00.000Z'),
          updatedAt: new Date('2026-08-01T00:00:00.000Z'),
        } as Freelancer),
      ),
    };
    service = new FreelancersService(repository);
  });

  describe('getFreelancers', () => {
    it('maps every freelancer to a response DTO', async () => {
      repository.findAll.mockResolvedValue([buildFreelancer()]);

      const result = await service.getFreelancers();

      expect(result).toEqual([
        {
          id: 'freelancer-1',
          fullName: 'Kulsum Zehra',
          role: 'Content Writer',
          notes: null,
          isActive: true,
          createdAt: '2026-08-01T00:00:00.000Z',
          updatedAt: '2026-08-01T00:00:00.000Z',
        },
      ]);
    });

    it('passes activeOnly through to the repository', async () => {
      await service.getFreelancers(true);
      expect(repository.findAll).toHaveBeenCalledWith(true);
    });
  });

  describe('createFreelancer', () => {
    it('creates an active freelancer', async () => {
      const result = await service.createFreelancer({
        fullName: 'Hamza Saqib',
        role: 'Data Entry',
      });

      expect(result.fullName).toBe('Hamza Saqib');
      expect(result.role).toBe('Data Entry');
      expect(result.isActive).toBe(true);
    });
  });

  describe('updateFreelancer', () => {
    it('applies only the defined fields', async () => {
      repository.findById.mockResolvedValue(buildFreelancer());

      const result = await service.updateFreelancer('freelancer-1', {
        isActive: false,
      });

      expect(result.isActive).toBe(false);
      expect(result.fullName).toBe('Kulsum Zehra');
    });

    it('throws NotFoundException for an unknown id', async () => {
      repository.findById.mockResolvedValue(null);

      await expect(
        service.updateFreelancer('nonexistent', { isActive: false }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });
});
