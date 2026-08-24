import { NotFoundException } from '@nestjs/common';
import { Lead } from '../domain/entities/lead.entity';
import type { LeadRepository } from '../domain/repositories/lead-repository.interface';
import { LeadsService } from './leads.service';

function buildLead(overrides: Partial<Lead> = {}): Lead {
  return {
    id: 'lead-1',
    leadDate: '2026-01-01',
    fullName: 'Jane Prospect',
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

  it('lists all leads', async () => {
    await service.getLeads();
    expect(leadRepository.findAll).toHaveBeenCalledWith();
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
  });

  it('updates a lead', async () => {
    leadRepository.findById.mockResolvedValue(buildLead());

    const result = await service.updateLead('lead-1', {
      fullName: 'Jane Updated',
    });

    expect(result.fullName).toBe('Jane Updated');
  });

  it('prepends a "+" to a phone number that lacks one on create', async () => {
    const result = await service.createLead({
      leadDate: '2026-01-01',
      fullName: 'Jane Prospect',
      phone: '92 300 1234567',
    });

    expect(result.phone).toBe('+92 300 1234567');
  });

  it('does not double up "+" on create when already present', async () => {
    const result = await service.createLead({
      leadDate: '2026-01-01',
      fullName: 'Jane Prospect',
      phone: '+92 300 1234567',
    });

    expect(result.phone).toBe('+92 300 1234567');
  });

  it('prepends a "+" to a phone number that lacks one on update', async () => {
    leadRepository.findById.mockResolvedValue(buildLead());

    const result = await service.updateLead('lead-1', {
      phone: '92 300 1234567',
    });

    expect(result.phone).toBe('+92 300 1234567');
  });

  it('does not store a blank optional field on create', async () => {
    const result = await service.createLead({
      leadDate: '2026-01-01',
      fullName: 'Jane Prospect',
      companyName: '   ',
    });

    expect(result.companyName).toBeNull();
  });

  it('clears a field to null when the editor sends "" rather than omitting it', async () => {
    leadRepository.findById.mockResolvedValue(
      buildLead({ remarks: 'Old remark' }),
    );

    const result = await service.updateLead('lead-1', { remarks: '' });

    expect(result.remarks).toBeNull();
  });

  it('leaves an untouched field alone on update', async () => {
    leadRepository.findById.mockResolvedValue(
      buildLead({ companyName: 'Acme Inc' }),
    );

    const result = await service.updateLead('lead-1', {
      fullName: 'Jane Updated',
    });

    expect(result.companyName).toBe('Acme Inc');
  });

  it('throws when updating a lead that does not exist', async () => {
    leadRepository.findById.mockResolvedValue(null);

    await expect(
      service.updateLead('missing', { fullName: 'Someone' }),
    ).rejects.toThrow(NotFoundException);
  });
});
