import { NotFoundException } from '@nestjs/common';
import { Lead } from '../domain/entities/lead.entity';
import type { LeadRepository } from '../domain/repositories/lead-repository.interface';
import { LeadsService } from './leads.service';

function buildLead(overrides: Partial<Lead> = {}): Lead {
  return {
    id: 'lead-1',
    leadDate: '2026-01-01',
    fullName: 'Jane Prospect',
    isArchived: false,
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    updatedAt: new Date('2026-01-01T00:00:00.000Z'),
    ...overrides,
  } as Lead;
}

describe('LeadsService', () => {
  let service: LeadsService;
  let leadRepository: jest.Mocked<LeadRepository>;

  beforeEach(() => {
    const stampTimestamps = (item: { createdAt?: Date; updatedAt?: Date }) => ({
      ...item,
      createdAt: item.createdAt ?? new Date('2026-01-01T00:00:00.000Z'),
      updatedAt: item.updatedAt ?? new Date('2026-01-01T00:00:00.000Z'),
    });

    leadRepository = {
      findAll: jest.fn().mockResolvedValue([]),
      findById: jest.fn(),
      save: jest.fn((item) => Promise.resolve(stampTimestamps(item) as Lead)),
    };

    service = new LeadsService(leadRepository);
  });

  it('lists only non-archived leads by default', async () => {
    await service.getLeads(false);
    expect(leadRepository.findAll).toHaveBeenCalledWith(false);
  });

  it('lists archived leads when requested', async () => {
    await service.getLeads(true);
    expect(leadRepository.findAll).toHaveBeenCalledWith(true);
  });

  it('creates a lead', async () => {
    const result = await service.createLead({
      leadDate: '2026-01-01',
      fullName: 'Jane Prospect',
      companyName: 'Acme Inc',
      leadSource: 'Referral',
      phone: '+1 555 0100',
      email: 'jane@acme.test',
      country: 'Pakistan',
      remarks: 'Interested in SEO',
      serviceInterested: 'SEO',
    });

    expect(result.fullName).toBe('Jane Prospect');
    expect(result.companyName).toBe('Acme Inc');
    expect(result.isArchived).toBe(false);
  });

  it('updates a lead, including archiving it', async () => {
    leadRepository.findById.mockResolvedValue(buildLead());

    const result = await service.updateLead('lead-1', { isArchived: true });

    expect(result.isArchived).toBe(true);
  });

  it('throws when updating a lead that does not exist', async () => {
    leadRepository.findById.mockResolvedValue(null);

    await expect(
      service.updateLead('missing', { fullName: 'Someone' }),
    ).rejects.toThrow(NotFoundException);
  });
});
